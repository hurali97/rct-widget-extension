
#import <react/renderer/core/LayoutableShadowNode.h>
#import <react/renderer/core/RawProps.h>
#import <react/renderer/core/ComponentDescriptor.h>
#import <react/renderer/debug/SystraceSection.h>
#import <react/renderer/mounting/TelemetryController.h>
#import <react/renderer/mounting/MountingCoordinator.h>
#import <react/renderer/components/view/ViewProps.h>

#import <React/RCTAssert.h>
#import <React/RCTFollyConvert.h>
#import <React/RCTUtils.h>
#import <React/RCTMountingTransactionObserverCoordinator.h>
#import <React/RCTComponentViewRegistry.h>

#import "RSUIMountingManager.h"
#import <RctWidgetExtension-Swift.h>

#if TARGET_OS_OSX
#import <QuartzCore/QuartzCore.h> // Includes CoreAnimation
#endif

using namespace facebook::react;

@interface RSUIComponentViewFactory ()
+ (folly::dynamic)dynamicPropsValueForProps:(Props::Shared const &)props;
+ (folly::dynamic)dynamicStateForState:(State::Shared const &)state;
@end

@interface RSUIDynamicObject ()
- (instancetype)mergeWith:(folly::dynamic)object;
- (void)updateObject:(folly::dynamic)object;
@end

@implementation RSUIMountingManager {
  RCTMountingTransactionObserverCoordinator _observerCoordinator;
  BOOL _transactionInFlight;
  BOOL _followUpTransactionRequired;

  RSUIComponentViewFactory *_componentViewFactory;
  RSUIViewRegistry *_viewRegistry;
}

- (instancetype)init
{
  if (self = [super init]) {
    _componentViewFactory = [RSUIComponentViewFactory standardComponentViewFactory];
    _viewRegistry = [RSUIViewRegistry new];
  }
  return self;
}

- (RSUIComponentViewFactory *)componentViewFactory
{
  return _componentViewFactory;
}

- (RSUIViewRegistry *)viewRegistry
{
  return _viewRegistry;
}

- (void)scheduleTransaction:(MountingCoordinator::Shared)mountingCoordinator
{
  if (RCTIsMainQueue()) {
    // Already on the proper thread, so:
    // * No need to do a thread jump;
    // * No need to do expensive copy of all mutations;
    // * No need to allocate a block.
    [self initiateTransaction:*mountingCoordinator];
    return;
  }

  RCTExecuteOnMainQueue(^{
    RCTAssertMainQueue();
    [self initiateTransaction:*mountingCoordinator];
  });
}

- (void)dispatchCommand:(ReactTag)reactTag commandName:(NSString *)commandName args:(NSArray *)args
{
  if (RCTIsMainQueue()) {
    // Already on the proper thread, so:
    // * No need to do a thread jump;
    // * No need to allocate a block.
    [self synchronouslyDispatchCommandOnUIThread:reactTag commandName:commandName args:args];
    return;
  }

  RCTExecuteOnMainQueue(^{
    RCTAssertMainQueue();
    [self synchronouslyDispatchCommandOnUIThread:reactTag commandName:commandName args:args];
  });
}

- (void)initiateTransaction:(MountingCoordinator const &)mountingCoordinator
{
  SystraceSection s("-[RCTMountingManager initiateTransaction:]");
  RCTAssertMainQueue();

  if (_transactionInFlight) {
    _followUpTransactionRequired = YES;
    return;
  }

  do {
    _followUpTransactionRequired = NO;
    _transactionInFlight = YES;
    [self performTransaction:mountingCoordinator];
    _transactionInFlight = NO;
  } while (_followUpTransactionRequired);
}

- (void)performTransaction:(MountingCoordinator const &)mountingCoordinator
{
  SystraceSection s("-[RCTMountingManager performTransaction:]");
  RCTAssertMainQueue();

  auto surfaceId = mountingCoordinator.getSurfaceId();

  mountingCoordinator.getTelemetryController().pullTransaction(
      [&](MountingTransaction const &transaction, SurfaceTelemetry const &surfaceTelemetry) {
        [self.delegate mountingManager:self willMountComponentsWithRootTag:surfaceId];
        _observerCoordinator.notifyObserversMountingTransactionWillMount(transaction, surfaceTelemetry);
      },
      [&](MountingTransaction const &transaction, SurfaceTelemetry const &surfaceTelemetry) {
          [self performMutations:transaction.getMutations()];
      },
      [&](MountingTransaction const &transaction, SurfaceTelemetry const &surfaceTelemetry) {
        _observerCoordinator.notifyObserversMountingTransactionDidMount(transaction, surfaceTelemetry);
        [self.delegate mountingManager:self didMountComponentsWithRootTag:surfaceId];
      });
}

- (void)synchronouslyUpdateViewOnUIThread:(ReactTag)reactTag
                             changedProps:(NSDictionary *)props
                      componentDescriptor:(const ComponentDescriptor &)componentDescriptor
{
//  RCTAssertMainQueue();
//  UIView<RCTComponentViewProtocol> *componentView = [_componentViewRegistry findComponentViewWithTag:reactTag];
//  SharedProps oldProps = [componentView props];
//  SharedProps newProps = componentDescriptor.cloneProps(oldProps, RawProps(convertIdToFollyDynamic(props)));
//  [componentView updateProps:newProps oldProps:oldProps];
}

- (void)synchronouslyDispatchCommandOnUIThread:(ReactTag)reactTag
                                   commandName:(NSString *)commandName
                                          args:(NSArray *)args
{
  RCTAssertMainQueue();
//  UIView<RCTComponentViewProtocol> *componentView = [_componentViewRegistry findComponentViewWithTag:reactTag];
//  [componentView handleCommand:commandName args:args];
  RSUIViewDescriptor *viewDescriptor = [_viewRegistry viewDescriptorForTag:reactTag];
  [viewDescriptor dispatchCommand:commandName withArgs:args];
}

#pragma mark - Performing mutations

- (void)performMutations:(ShadowViewMutationList const &)mutations
{
  SystraceSection s("RCTPerformMountInstructions");

  [CATransaction begin];
  [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
  for (auto const &mutation : mutations) {
    switch (mutation.type) {
      case ShadowViewMutation::Create: {
        auto &newChildShadowView = mutation.newChildShadowView;
        auto &layoutMetrics = newChildShadowView.layoutMetrics;

        NSLog(@"Create %s with tag %d", newChildShadowView.componentName, newChildShadowView.tag);
        RSUIViewDescriptor *viewDescriptor = [_viewRegistry create:newChildShadowView.tag name:@(newChildShadowView.componentName)];

        [self updateViewDescriptor:viewDescriptor withNewProps:newChildShadowView.props];

        folly::dynamic const &newState = [RSUIComponentViewFactory dynamicStateForState:newChildShadowView.state];
        [viewDescriptor.shadowNodeState updateObject:newState];

        [viewDescriptor updateLayoutMetricsWithX:layoutMetrics.frame.origin.x
                                               y:layoutMetrics.frame.origin.y
                                           width:layoutMetrics.frame.size.width
                                          height:layoutMetrics.frame.size.height
                                contentLeftInset:layoutMetrics.contentInsets.left
                                 contentTopInset:layoutMetrics.contentInsets.top
                               contentRightInset:layoutMetrics.contentInsets.right
                              contentBottomInset:layoutMetrics.contentInsets.bottom];

        [viewDescriptor.eventEmitter setInternalEventEmitter:newChildShadowView.eventEmitter.get()];

        [viewDescriptor commitUpdates];
        break;
      }

      case ShadowViewMutation::Delete: {
        auto &oldChildShadowView = mutation.oldChildShadowView;

        NSLog(@"Delete %s with tag %d", oldChildShadowView.componentName, oldChildShadowView.tag);
        [_viewRegistry delete:oldChildShadowView.tag];
        break;
      }

      case ShadowViewMutation::Insert: {
        auto &newChildShadowView = mutation.newChildShadowView;
        auto &parentShadowView = mutation.parentShadowView;

        NSLog(@"Insert %s with tag %d to %d", newChildShadowView.componentName, newChildShadowView.tag, parentShadowView.tag);
        [_viewRegistry insert:newChildShadowView.tag toParent:parentShadowView.tag atIndex:mutation.index];
        break;
      }

      case ShadowViewMutation::Remove: {
        auto &oldChildShadowView = mutation.oldChildShadowView;
        auto &parentShadowView = mutation.parentShadowView;

        NSLog(@"Remove %s with tag %d", oldChildShadowView.componentName, oldChildShadowView.tag);
        [_viewRegistry remove:oldChildShadowView.tag fromParent:parentShadowView.tag];
        break;
      }

      case ShadowViewMutation::Update: {
        auto &oldChildShadowView = mutation.oldChildShadowView;
        auto &newChildShadowView = mutation.newChildShadowView;
        RSUIViewDescriptor *viewDescriptor = [_viewRegistry viewDescriptorForTag:newChildShadowView.tag];

        auto mask = RNComponentViewUpdateMask{};

        if (oldChildShadowView.props != newChildShadowView.props) {
          NSLog(@"Update %s props with tag %d", newChildShadowView.componentName, newChildShadowView.tag);
          [self updateViewDescriptor:viewDescriptor withNewProps:newChildShadowView.props];
          mask |= RNComponentViewUpdateMaskProps;
        }

        if (oldChildShadowView.state != newChildShadowView.state) {
          NSLog(@"Update %s state with tag %d", newChildShadowView.componentName, newChildShadowView.tag);
          folly::dynamic const &newState = [RSUIComponentViewFactory dynamicStateForState:newChildShadowView.state];
          [viewDescriptor.shadowNodeState updateObject:newState];
          mask |= RNComponentViewUpdateMaskState;
        }

        if (oldChildShadowView.eventEmitter != newChildShadowView.eventEmitter) {
          NSLog(@"Update %s emitter with tag %d", newChildShadowView.componentName, newChildShadowView.tag);
          [viewDescriptor.eventEmitter setInternalEventEmitter:newChildShadowView.eventEmitter.get()];
          mask |= RNComponentViewUpdateMaskEventEmitter;
        }

        if (oldChildShadowView.layoutMetrics != newChildShadowView.layoutMetrics) {
          auto const &layoutMetrics = newChildShadowView.layoutMetrics;
          NSLog(@"Update %s metrics with tag %d", newChildShadowView.componentName, newChildShadowView.tag);

          [viewDescriptor updateLayoutMetricsWithX:layoutMetrics.frame.origin.x
                                                 y:layoutMetrics.frame.origin.y
                                             width:layoutMetrics.frame.size.width
                                            height:layoutMetrics.frame.size.height
                                  contentLeftInset:layoutMetrics.contentInsets.left
                                   contentTopInset:layoutMetrics.contentInsets.top
                                 contentRightInset:layoutMetrics.contentInsets.right
                                contentBottomInset:layoutMetrics.contentInsets.bottom];
          mask |= RNComponentViewUpdateMaskLayoutMetrics;
        }
        if (mask != RNComponentViewUpdateMaskNone) {
          [viewDescriptor commitUpdates];
        }
        break;
      }
    }
  }
  [CATransaction commit];
}

#pragma mark - Updating view descriptors

- (void)updateViewDescriptor:(RSUIViewDescriptor *)viewDescriptor withNewProps:(const Props::Shared &)newProps
{
  viewDescriptor.props = [viewDescriptor.props mergeWith:[RSUIComponentViewFactory dynamicPropsValueForProps:newProps]];
}

@end
