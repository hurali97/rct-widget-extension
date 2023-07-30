
#import "RSUIMountingManagerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSInteger ReactTag;

@class RCTComponentViewRegistry;

/**
 * Manages mounting process.
 */
@interface RSUIMountingManager : NSObject

@property (nonatomic, weak) id<RSUIMountingManagerDelegate> delegate;

- (id)componentViewFactory;

- (id)viewRegistry;

/**
 * Schedule a mounting transaction to be performed on the main thread.
 * Can be called from any thread.
 */
- (void)scheduleTransaction:(facebook::react::MountingCoordinator::Shared)mountingCoordinator;

/**
 * Dispatch a command to be performed on the main thread.
 * Can be called from any thread.
 */
- (void)dispatchCommand:(ReactTag)reactTag commandName:(NSString *)commandName args:(NSArray *)args;

//- (void)synchronouslyUpdateViewOnUIThread:(ReactTag)reactTag
//                             changedProps:(NSDictionary *)props
//                      componentDescriptor:(const facebook::react::ComponentDescriptor &)componentDescriptor;

/**
 * Designates the view as a rendering viewport of a React Native surface.
 * The provided view must not have any subviews, and the caller is not supposed to interact with the view hierarchy
 * inside the provided view. The view hierarchy created by mounting infrastructure inside the provided view does not
 * influence the intrinsic size of the view and cannot be measured using UIView/UIKit layout API.
 * Must be called on the main thead.
 */
- (void)attachSurfaceToView:(UIView *)view surfaceId:(facebook::react::SurfaceId)surfaceId;

/**
 * Stops designating the view as a rendering viewport of a React Native surface.
 */
- (void)detachSurfaceFromView:(UIView *)view surfaceId:(facebook::react::SurfaceId)surfaceId;

@end

NS_ASSUME_NONNULL_END
