
#import <React-runtimeexecutor/ReactCommon/RuntimeExecutor.h>

#import <React/RCTSurfacePresenterStub.h>

#import <react/utils/ContextContainer.h>

#import "RSUISurface.h"
#import "RSUIScheduler.h"
#import "RSUIMountingManagerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSInteger ReactTag;

using namespace facebook::react;

@interface RSUISurfacePresenter : NSObject <RCTSurfacePresenterStub, RSUISchedulerDelegate, RSUIMountingManagerDelegate>

- (instancetype)initWithContextContainer:(ContextContainer::Shared)contextContainer
                         runtimeExecutor:(RuntimeExecutor)runtimeExecutor;

@property (nonatomic) ContextContainer::Shared contextContainer;
@property (nonatomic) RuntimeExecutor runtimeExecutor;

- (id)viewRegistry;
@property (readonly) RSUIMountingManager *mountingManager;

/*
 * Suspends/resumes all surfaces associated with the presenter.
 * Suspending is a process or gracefull stopping all surfaces and destroying all underlying infrastructure
 * with a future possibility of recreating the infrastructure and restarting the surfaces from scratch.
 * Suspending is usually a part of a bundle reloading process.
 * Can be called on any thread.
 */
- (BOOL)suspend;
- (BOOL)resume;

/**
 * Surface uses these methods to register itself in the Presenter.
 */
- (void)registerSurface:(RSUISurface *)surface;
- (void)unregisterSurface:(RSUISurface *)surface;

- (void)setProps:(NSDictionary *)props surface:(RSUISurface *)surface;

- (nullable RSUISurface *)surfaceForRootTag:(ReactTag)rootTag;

- (BOOL)synchronouslyUpdateViewOnUIThread:(NSNumber *)reactTag props:(NSDictionary *)props;

- (void)addObserver:(id<RCTSurfacePresenterObserver>)observer;

- (void)removeObserver:(id<RCTSurfacePresenterObserver>)observer;

/*
 * Please do not use this, this will be deleted soon.
 */
- (id)findComponentViewWithTag_DO_NOT_USE_DEPRECATED:(NSInteger)tag;

@end

NS_ASSUME_NONNULL_END
