#pragma once

#include <react/renderer/components/text/BaseTextProps.h>
#include <react/renderer/components/text/BaseTextShadowNode.h>
#include <react/renderer/core/ConcreteComponentDescriptor.h>
#include <react/renderer/components/view/ViewEventEmitter.h>
#include <react/renderer/core/ConcreteShadowNode.h>

#include "RSUIComponentDescriptor.h"

#pragma once

using namespace facebook::react;

char const RSUITextComponentName[] = "RSUITextView";

class RSUITextProps : public Props, public BaseTextProps, public RSUIDynamicProps {
public:
  RSUITextProps() {}
  RSUITextProps(const PropsParserContext &context, const RSUITextProps &sourceProps, const RawProps &rawProps)
    : Props(context, sourceProps, rawProps),
      BaseTextProps::BaseTextProps(context, sourceProps, rawProps),
      RSUIDynamicProps(rawProps) {};
    
    void setProp(
        const PropsParserContext &context,
        RawPropsPropNameHash hash,
        const char *propName,
        RawValue const &value);
};

using TextEventEmitter = TouchEventEmitter;

class RSUITextShadowNode : public ConcreteShadowNode<RSUITextComponentName, ShadowNode, RSUITextProps, TextEventEmitter>, public BaseTextShadowNode {
public:
  static ShadowNodeTraits BaseTraits() {
    auto traits = ConcreteShadowNode::BaseTraits();

#ifdef ANDROID
    traits.set(ShadowNodeTraits::Trait::FormsView);
#endif

    return traits;
  }

  using ConcreteShadowNode::ConcreteShadowNode;
};

using RSUITextDescriptor = ConcreteComponentDescriptor<RSUITextShadowNode>;
