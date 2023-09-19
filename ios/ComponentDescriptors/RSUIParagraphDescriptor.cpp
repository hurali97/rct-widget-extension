/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include <cmath>

#include <react/renderer/attributedstring/AttributedStringBox.h>
#include <react/renderer/components/view/ViewShadowNode.h>
#include <react/renderer/components/view/conversions.h>
#include <react/renderer/core/TraitCast.h>

#include "RSUIParagraphDescriptor.h"
#include "RSUIRawTextDescriptor.h"
#include "RSUITextDescriptor.h"

inline ShadowView shadowViewFromShadowNode(ShadowNode const &shadowNode) {
  auto shadowView = ShadowView{shadowNode};
  // Clearing `props` and `state` (which we don't use) allows avoiding retain
  // cycles.
  shadowView.props = nullptr;
  shadowView.state = nullptr;
  return shadowView;
}

using Content = RSUIParagraphShadowNode::Content;

Content const &RSUIParagraphShadowNode::getContent(
    LayoutContext const &layoutContext) const {
  if (content_.has_value()) {
    return content_.value();
  }

  ensureUnsealed();

  auto textAttributes = TextAttributes::defaultTextAttributes();
  textAttributes.fontSizeMultiplier = layoutContext.fontSizeMultiplier;
  textAttributes.apply(getConcreteProps().textAttributes);
  textAttributes.layoutDirection =
      YGNodeLayoutGetDirection(&yogaNode_) == YGDirectionRTL
      ? LayoutDirection::RightToLeft
      : LayoutDirection::LeftToRight;
  auto attributedString = AttributedString{};
  auto attachments = Attachments{};
  buildAttributedString(textAttributes, *this, attributedString, attachments);

  content_ = Content{
      attributedString, getConcreteProps().paragraphAttributes, attachments};

  return content_.value();
}

Content RSUIParagraphShadowNode::getContentWithMeasuredAttachments(
    LayoutContext const &layoutContext,
    LayoutConstraints const &layoutConstraints) const {
  auto content = getContent(layoutContext);

  if (content.attachments.empty()) {
    // Base case: No attachments, nothing to do.
    return content;
  }

  auto localLayoutConstraints = layoutConstraints;
  // Having enforced minimum size for text fragments doesn't make much sense.
  localLayoutConstraints.minimumSize = Size{0, 0};

  auto &fragments = content.attributedString.getFragments();

  for (auto const &attachment : content.attachments) {
    auto laytableShadowNode =
        traitCast<LayoutableShadowNode const *>(attachment.shadowNode);

    if (laytableShadowNode == nullptr) {
      continue;
    }

    auto size =
        laytableShadowNode->measure(layoutContext, localLayoutConstraints);

    // Rounding to *next* value on the pixel grid.
    size.width += 0.01f;
    size.height += 0.01f;
    size = roundToPixel<&ceil>(size, layoutContext.pointScaleFactor);

    auto fragmentLayoutMetrics = LayoutMetrics{};
    fragmentLayoutMetrics.pointScaleFactor = layoutContext.pointScaleFactor;
    fragmentLayoutMetrics.frame.size = size;
    fragments[attachment.fragmentIndex].parentShadowView.layoutMetrics =
        fragmentLayoutMetrics;
  }

  return content;
}

void RSUIParagraphShadowNode::setTextLayoutManager(
                                                   std::shared_ptr<TextLayoutManager const> textLayoutManager) {
                                                 ensureUnsealed();
                                                 getStateData().paragraphLayoutManager.setTextLayoutManager(
                                                     std::move(textLayoutManager));
                                               }

void RSUIParagraphShadowNode::updateStateIfNeeded(Content const &content) {
  ensureUnsealed();

  auto &state = getStateData();

    react_native_assert(state.paragraphLayoutManager.getTextLayoutManager());

    if (state.attributedString == content.attributedString) {
      return;
    }

    setStateData(RSUIParagraphState{
        content.attributedString,
        content.paragraphAttributes,
        state.paragraphLayoutManager});
}

#pragma mark - LayoutableShadowNode

facebook::react::Size RSUIParagraphShadowNode::measureContent(
    LayoutContext const &layoutContext,
    LayoutConstraints const &layoutConstraints) const {
  auto content =
      getContentWithMeasuredAttachments(layoutContext, layoutConstraints);

  auto attributedString = content.attributedString;
  if (attributedString.isEmpty()) {
    // Note: `zero-width space` is insufficient in some cases (e.g. when we need
    // to measure the "height" of the font).
    // TODO T67606511: We will redefine the measurement of empty strings as part
    // of T67606511
    auto string = BaseTextShadowNode::getEmptyPlaceholder();
    auto textAttributes = TextAttributes::defaultTextAttributes();
    textAttributes.fontSizeMultiplier = layoutContext.fontSizeMultiplier;
    textAttributes.apply(getConcreteProps().textAttributes);
    attributedString.appendFragment({string, textAttributes, {}});
  }

        return getStateData()
            .paragraphLayoutManager
            .measure(attributedString, content.paragraphAttributes, layoutConstraints)
            .size;
}

void RSUIParagraphShadowNode::layout(LayoutContext layoutContext) {
  ensureUnsealed();

  auto layoutMetrics = getLayoutMetrics();
  auto availableSize = layoutMetrics.getContentFrame().size;

  auto layoutConstraints = LayoutConstraints{
      availableSize, availableSize, layoutMetrics.layoutDirection};
  auto content =
      getContentWithMeasuredAttachments(layoutContext, layoutConstraints);

  updateStateIfNeeded(content);

    auto measurement = getStateData().paragraphLayoutManager.measure(
        content.attributedString, content.paragraphAttributes, layoutConstraints);

    if (getConcreteProps().onTextLayout) {
      auto linesMeasurements = getStateData().paragraphLayoutManager.measureLines(
          content.attributedString,
          content.paragraphAttributes,
          measurement.size);
      getConcreteEventEmitter().onTextLayout(linesMeasurements);
    }

  if (content.attachments.empty()) {
    // No attachments, nothing to layout.
    return;
  }

  //  Iterating on attachments, we clone shadow nodes and moving
  //  `paragraphShadowNode` that represents clones of `this` object.
  auto paragraphShadowNode = static_cast<RSUIParagraphShadowNode *>(this);
  // `paragraphOwningShadowNode` is owning pointer to`paragraphShadowNode`
  // (besides the initial case when `paragraphShadowNode == this`), we need this
  // only to keep it in memory for a while.
  auto paragraphOwningShadowNode = ShadowNode::Unshared{};

  assert(content.attachments.size() == measurement.attachments.size());

  for (auto i = 0; i < content.attachments.size(); i++) {
    auto &attachment = content.attachments.at(i);

    if (!traitCast<LayoutableShadowNode const *>(attachment.shadowNode)) {
      // Not a layoutable `ShadowNode`, no need to lay it out.
      continue;
    }

    auto clonedShadowNode = ShadowNode::Unshared{};

    paragraphOwningShadowNode = paragraphShadowNode->cloneTree(
        attachment.shadowNode->getFamily(),
        [&](ShadowNode const &oldShadowNode) {
          clonedShadowNode = oldShadowNode.clone({});
          return clonedShadowNode;
        });
    paragraphShadowNode =
        static_cast<RSUIParagraphShadowNode *>(paragraphOwningShadowNode.get());

    auto &layoutableShadowNode = const_cast<LayoutableShadowNode &>(
        traitCast<LayoutableShadowNode const &>(*clonedShadowNode));

    auto attachmentFrame = measurement.attachments[i].frame;
    auto attachmentSize = roundToPixel<&ceil>(
        attachmentFrame.size, layoutMetrics.pointScaleFactor);
    auto attachmentOrigin = roundToPixel<&round>(
        attachmentFrame.origin, layoutMetrics.pointScaleFactor);
    auto attachmentLayoutContext = layoutContext;
    auto attachmentLayoutConstrains = LayoutConstraints{
        attachmentSize, attachmentSize, layoutConstraints.layoutDirection};

    // Laying out the `ShadowNode` and the subtree starting from it.
    layoutableShadowNode.layoutTree(
        attachmentLayoutContext, attachmentLayoutConstrains);

    // Altering the origin of the `ShadowNode` (which is defined by text layout,
    // not by internal styles and state).
    auto attachmentLayoutMetrics = layoutableShadowNode.getLayoutMetrics();
    attachmentLayoutMetrics.frame.origin = attachmentOrigin;
    layoutableShadowNode.setLayoutMetrics(attachmentLayoutMetrics);
  }

  // If we ended up cloning something, we need to update the list of children to
  // reflect the changes that we made.
  if (paragraphShadowNode != this) {
    this->children_ =
        static_cast<RSUIParagraphShadowNode const *>(paragraphShadowNode)
            ->children_;
  }
}

void RSUIParagraphShadowNode::buildAttributedString(
    TextAttributes const &baseTextAttributes,
    ShadowNode const &parentNode,
    AttributedString &outAttributedString,
    Attachments &outAttachments) {
  for (auto const &childNode : parentNode.getChildren()) {
    // RawShadowNode
    auto rawTextShadowNode =
        std::dynamic_pointer_cast<RSUIRawTextShadowNode const>(childNode);
    if (rawTextShadowNode) {
      auto fragment = AttributedString::Fragment{};
      fragment.string = rawTextShadowNode->getConcreteProps().text;
      fragment.textAttributes = baseTextAttributes;

      // Storing a retaining pointer to `ParagraphShadowNode` inside
      // `attributedString` causes a retain cycle (besides that fact that we
      // don't need it at all). Storing a `ShadowView` instance instead of
      // `ShadowNode` should properly fix this problem.
      fragment.parentShadowView = shadowViewFromShadowNode(parentNode);
      outAttributedString.appendFragment(fragment);
      continue;
    }

    // TextShadowNode
    auto textShadowNode =
        std::dynamic_pointer_cast<RSUITextShadowNode const>(childNode);
    if (textShadowNode) {
      auto localTextAttributes = baseTextAttributes;
      localTextAttributes.apply(
          textShadowNode->getConcreteProps().textAttributes);
      buildAttributedString(
          localTextAttributes,
          *textShadowNode,
          outAttributedString,
          outAttachments);
      continue;
    }

    // Any *other* kind of ShadowNode
    auto fragment = AttributedString::Fragment{};
    fragment.string = AttributedString::Fragment::AttachmentCharacter();
    fragment.parentShadowView = shadowViewFromShadowNode(*childNode);
    fragment.textAttributes = baseTextAttributes;
    outAttributedString.appendFragment(fragment);
    outAttachments.push_back(Attachment{
        childNode.get(), outAttributedString.getFragments().size() - 1});
  }
}
