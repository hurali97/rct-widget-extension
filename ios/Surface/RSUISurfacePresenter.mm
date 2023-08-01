
#import <mutex>
#import <shared_mutex>

#import <react/renderer/components/root/RootShadowNode.h>
#import <react/utils/ManagedObjectWrapper.h>
#import <react/utils/RunLoopObserver.h>
#import <react/renderer/scheduler/SchedulerToolbox.h>
#import <react/config/ReactNativeConfig.h>
#import <react/renderer/scheduler/SynchronousEventBeat.h>
#import <react/renderer/scheduler/AsynchronousEventBeat.h>

#import <React/RCTUtils.h>
#import <React/RCTSurfaceStage.h>
#import <React/RCTUtils.h>
#import <React/RCTI18nUtil.h>
#import <React/RCTSurfaceRootView.h>
#import <React/RCTSurfaceView+Internal.h>
#import <React/RCTFollyConvert.h>

#import "RSUISurface.h"
#import "RSUISurfaceView.h"
#import "RSUISurfacePresenter.h"
#import "RSUISurfaceRegistry.h"
#import "RSUIMountingManager.h"
#import "RSUIRuntimeEventBeat.h"
#import "RSUIMainRunLoopEventBeat.h"
#import "RSUIPlatformRunLoopObserver.h"

#import <RctWidgetExtension-Swift.h>

using namespace facebook;
using namespace facebook::react;

static dispatch_queue_t RCTGetBackgroundQueue()
{
  static dispatch_queue_t queue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dispatch_queue_attr_t attr =
        dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
    queue = dispatch_queue_create("com.facebook.react.background", attr);
  });
  return queue;
}

static BackgroundExecutor RCTGetBackgroundExecutor()
{
  return [](std::function<void()> &&callback) {
    if (RCTIsMainQueue()) {
      callback();
      return;
    }

    auto copyableCallback = callback;
    dispatch_async(RCTGetBackgroundQueue(), ^{
      copyableCallback();
    });
  };
}

@interface RSUIComponentViewFactory ()
- (ComponentDescriptorRegistry::Shared)createComponentDescriptorRegistryWithParameters:(ComponentDescriptorParameters)parameters;
@end

@implementation RSUISurfacePresenter {
  // Protected by `_schedulerLifeCycleMutex`.
  std::mutex _schedulerLifeCycleMutex;
  ContextContainer::Shared _contextContainer;
  RuntimeExecutor _runtimeExecutor;

  // Protected by `_schedulerAccessMutex`.
  std::mutex _schedulerAccessMutex;
  RSUIScheduler *_Nullable _scheduler;

  // Protected by `_observerListMutex`.
  std::shared_mutex _observerListMutex;
  NSMutableArray<id<RCTSurfacePresenterObserver>> *_observers;

  RSUIMountingManager *_mountingManager; // Thread-safe.
  RSUISurfaceRegistry *_surfaceRegistry; // Thread-safe.
}

- (instancetype)initWithContextContainer:(ContextContainer::Shared)contextContainer
                         runtimeExecutor:(RuntimeExecutor)runtimeExecutor
{
  if (self = [super init]) {
    _contextContainer = contextContainer;
    _runtimeExecutor = runtimeExecutor;

    _surfaceRegistry = [RSUISurfaceRegistry new];
    _mountingManager = [RSUIMountingManager new];
    _mountingManager.delegate = self;

    _observers = [NSMutableArray array];

    _scheduler = [self createScheduler];
  }
  return self;
}

- (RSUIViewRegistry *)viewRegistry
{
  return _mountingManager.viewRegistry;
}

- (RSUIMountingManager *)mountingManager
{
  return _mountingManager;
}

#pragma mark - Mutex-protected members

- (nullable RSUIScheduler *)_scheduler
{
  std::lock_guard<std::mutex> lock(_schedulerAccessMutex);
  return _scheduler;
}

- (ContextContainer::Shared)contextContainer
{
  std::lock_guard<std::mutex> lock(_schedulerLifeCycleMutex);
  return _contextContainer;
}

- (void)setContextContainer:(ContextContainer::Shared)contextContainer
{
  std::lock_guard<std::mutex> lock(_schedulerLifeCycleMutex);
  _contextContainer = contextContainer;
}

- (RuntimeExecutor)runtimeExecutor
{
  std::lock_guard<std::mutex> lock(_schedulerLifeCycleMutex);
  return _runtimeExecutor;
}

- (void)setRuntimeExecutor:(RuntimeExecutor)runtimeExecutor
{
  std::lock_guard<std::mutex> lock(_schedulerLifeCycleMutex);
  _runtimeExecutor = runtimeExecutor;
}

#pragma mark - Internal Surface-dedicated Interface

- (void)registerSurface:(RSUISurface *)surface
{
  RSUIScheduler *scheduler = [self _scheduler];
  [_surfaceRegistry registerSurface:surface];
  if (scheduler) {
    [self startSurface:surface scheduler:scheduler];
  }
}

- (void)unregisterSurface:(RSUISurface *)surface
{
  RSUIScheduler *scheduler = [self _scheduler];
  if (scheduler) {
    [self stopSurface:surface scheduler:scheduler];
  }
  [_surfaceRegistry unregisterSurface:surface];
}

- (void)setProps:(NSDictionary *)props surface:(RSUISurface *)surface
{
  RSUIScheduler *scheduler = [self _scheduler];
  if (scheduler) {
    [self stopSurface:surface scheduler:scheduler];
    [self startSurface:surface scheduler:scheduler];
  }
}

- (RSUISurface *)surfaceForRootTag:(ReactTag)rootTag
{
  return [_surfaceRegistry surfaceForRootTag:rootTag];
}

- (id)findComponentViewWithTag_DO_NOT_USE_DEPRECATED:(NSInteger)tag
{
//  UIView<RCTComponentViewProtocol> *componentView =
//      [_mountingManager.componentViewRegistry findComponentViewWithTag:tag];
//  return componentView;
  return nil;
}

- (BOOL)synchronouslyUpdateViewOnUIThread:(NSNumber *)reactTag props:(NSDictionary *)props
{
//  RSUIScheduler *scheduler = [self _scheduler];
//  if (!scheduler) {
//    return NO;
//  }

//  ReactTag tag = [reactTag integerValue];
//  UIView<RCTComponentViewProtocol> *componentView =
//      [_mountingManager.componentViewRegistry findComponentViewWithTag:tag];
//  if (componentView == nil) {
//    return NO; // This view probably isn't managed by Fabric
//  }
//  ComponentHandle handle = [[componentView class] componentDescriptorProvider].handle;
//  auto *componentDescriptor = [scheduler findComponentDescriptorByHandle_DO_NOT_USE_THIS_IS_BROKEN:handle];

//  if (!componentDescriptor) {
//    return YES;
//  }

//  [_mountingManager synchronouslyUpdateViewOnUIThread:tag changedProps:props componentDescriptor:*componentDescriptor];
  return NO;
}

- (BOOL)suspend
{
  std::lock_guard<std::mutex> lock(_schedulerLifeCycleMutex);

  RSUIScheduler *scheduler;
  {
    std::lock_guard<std::mutex> accessLock(_schedulerAccessMutex);

    if (!_scheduler) {
      return NO;
    }
    scheduler = _scheduler;
    _scheduler = nil;
  }

  [self stopAllSurfacesWithScheduler:scheduler];

  return YES;
}

- (BOOL)resume
{
  std::lock_guard<std::mutex> lock(_schedulerLifeCycleMutex);

  RSUIScheduler *scheduler;
  {
    std::lock_guard<std::mutex> accessLock(_schedulerAccessMutex);

    if (_scheduler) {
      return NO;
    }
    scheduler = [self createScheduler];
  }

  [self startAllSurfacesWithScheduler:scheduler];

  {
    std::lock_guard<std::mutex> accessLock(_schedulerAccessMutex);
    _scheduler = scheduler;
  }

  return YES;
}

#pragma mark - Observers

- (void)addObserver:(nonnull id<RCTSurfacePresenterObserver>)observer
{
  std::unique_lock lock(_observerListMutex);
  [_observers addObject:observer];
}

- (void)removeObserver:(nonnull id<RCTSurfacePresenterObserver>)observer
{
  std::unique_lock lock(_observerListMutex);
  [_observers removeObject: observer];
}

#pragma mark - RSUISchedulerDelegate

- (void)schedulerDidFinishTransaction:(MountingCoordinator::Shared)mountingCoordinator
{
  [_mountingManager scheduleTransaction:mountingCoordinator];
}

- (void)schedulerDidDispatchCommand:(const facebook::react::ShadowView &)shadowView
                        commandName:(const std::string &)commandName args:(const folly::dynamic &)args
{
  ReactTag tag = shadowView.tag;
  NSString *commandStr = [[NSString alloc] initWithUTF8String:commandName.c_str()];
  NSArray *argsArray = convertFollyDynamicToId(args);

  [self->_mountingManager dispatchCommand:tag commandName:commandStr args:argsArray];
}

#pragma mark - RSUIMountingManagerDelegate

- (void)mountingManager:(RSUIMountingManager *)mountingManager willMountComponentsWithRootTag:(ReactTag)rootTag
{
  RCTAssertMainQueue();

  std::shared_lock lock(_observerListMutex);
  for (id<RCTSurfacePresenterObserver> observer in _observers) {
    if ([observer respondsToSelector:@selector(willMountComponentsWithRootTag:)]) {
      [observer willMountComponentsWithRootTag:rootTag];
    }
  }
}

- (void)mountingManager:(RSUIMountingManager *)mountingManager didMountComponentsWithRootTag:(ReactTag)rootTag
{
  RCTAssertMainQueue();
    
    NSArray<id<RCTSurfacePresenterObserver>> *observersCopy;
    {
      std::shared_lock lock(_observerListMutex);
      observersCopy = [self _getObservers];
    }

  RSUISurface *surface = [_surfaceRegistry surfaceForRootTag:rootTag];
  RCTSurfaceStage stage = surface.stage;
//  if (stage & RCTSurfaceStagePrepared) {
//    // We have to progress the stage only if the preparing phase is done.
//    if ([surface setStage:RCTSurfaceStageMounted]) {
//      [surface.view mountContentView];
//    }
//  }

  std::shared_lock lock(_observerListMutex);
  for (id<RCTSurfacePresenterObserver> observer in _observers) {
    if ([observer respondsToSelector:@selector(didMountComponentsWithRootTag:)]) {
      [observer didMountComponentsWithRootTag:rootTag];
    }
  }
}

#pragma mark - Private

- (nonnull RSUIScheduler *)createScheduler
{
    auto reactNativeConfig = _contextContainer->at<std::shared_ptr<ReactNativeConfig const>>("ReactNativeConfig");

    if (reactNativeConfig && reactNativeConfig->getBool("rn_convergence:dispatch_pointer_events")) {
      RCTSetDispatchW3CPointerEvents(YES);
    }

    if (reactNativeConfig && reactNativeConfig->getBool("react_fabric:enable_cpp_props_iterator_setter_ios")) {
      CoreFeatures::enablePropIteratorSetter = true;
    }

    if (reactNativeConfig && reactNativeConfig->getBool("react_fabric:use_native_state")) {
      CoreFeatures::useNativeState = true;
    }

    if (reactNativeConfig && reactNativeConfig->getBool("react_fabric:enable_nstextstorage_caching")) {
      CoreFeatures::cacheNSTextStorage = true;
    }

    if (reactNativeConfig && reactNativeConfig->getBool("react_fabric:cancel_image_downloads_on_recycle")) {
      CoreFeatures::cancelImageDownloadsOnRecycle = true;
    }
    
  auto componentRegistryFactory = [factory = wrapManagedObject(_mountingManager.componentViewFactory)](EventDispatcher::Weak const &eventDispatcher, ContextContainer::Shared const &contextContainer) {
    return [(RSUIComponentViewFactory *)unwrapManagedObject(factory) createComponentDescriptorRegistryWithParameters:{eventDispatcher, contextContainer}];
  };

  auto runtimeExecutor = _runtimeExecutor;
    
    auto weakRuntimeScheduler = _contextContainer->find<std::weak_ptr<RuntimeScheduler>>("RuntimeScheduler");
    auto runtimeScheduler = weakRuntimeScheduler.has_value() ? weakRuntimeScheduler.value().lock() : nullptr;
    if (runtimeScheduler) {
      runtimeExecutor = [runtimeScheduler](std::function<void(jsi::Runtime & runtime)> &&callback) {
        runtimeScheduler->scheduleWork(std::move(callback));
      };
    }
    
  auto toolbox = SchedulerToolbox{};
  toolbox.contextContainer = _contextContainer;
  toolbox.componentRegistryFactory = componentRegistryFactory;
  toolbox.runtimeExecutor = runtimeExecutor;
  toolbox.mainRunLoopObserverFactory = [](RunLoopObserver::Activity activities,
                                          RunLoopObserver::WeakOwner const &owner) {
    return std::make_unique<MainRunLoopObserver>(activities, owner);
  };
    
    if (reactNativeConfig && reactNativeConfig->getBool("react_fabric:enable_background_executor_ios")) {
      toolbox.backgroundExecutor = RCTGetBackgroundExecutor();
    }

    toolbox.synchronousEventBeatFactory =
        [runtimeExecutor, runtimeScheduler = runtimeScheduler](EventBeat::SharedOwnerBox const &ownerBox) {
          auto runLoopObserver =
              std::make_unique<MainRunLoopObserver const>(RunLoopObserver::Activity::BeforeWaiting, ownerBox->owner);
          return std::make_unique<SynchronousEventBeat>(std::move(runLoopObserver), runtimeExecutor, runtimeScheduler);
        };

    toolbox.asynchronousEventBeatFactory =
        [runtimeExecutor](EventBeat::SharedOwnerBox const &ownerBox) -> std::unique_ptr<EventBeat> {
      auto runLoopObserver =
          std::make_unique<MainRunLoopObserver const>(RunLoopObserver::Activity::BeforeWaiting, ownerBox->owner);
      return std::make_unique<AsynchronousEventBeat>(std::move(runLoopObserver), runtimeExecutor);
    };

  RSUIScheduler *scheduler = [[RSUIScheduler alloc] initWithToolbox:toolbox];
  scheduler.delegate = self;

  return scheduler;
}

- (void)startSurface:(RSUISurface *)surface scheduler:(RSUIScheduler *)scheduler
{
  RSUIMountingManager *mountingManager = _mountingManager;
  RCTExecuteOnMainQueue(^{
    [mountingManager.viewRegistry create:(int)surface.rootTag name:@"RootView"];
  });

  [scheduler registerSurface:surface.surfaceHandler];
  [surface start];
}

- (void)stopSurface:(RSUISurface *)surface scheduler:(RSUIScheduler *)scheduler
{
    [surface stop];
    [scheduler unregisterSurface:surface.surfaceHandler];
}

- (void)startAllSurfacesWithScheduler:(RSUIScheduler *)scheduler
{
  [_surfaceRegistry enumerateWithBlock:^(NSEnumerator<RSUISurface *> *enumerator) {
    for (RSUISurface *surface in enumerator) {
      [self startSurface:surface scheduler:scheduler];
    }
  }];
}

- (void)stopAllSurfacesWithScheduler:(RSUIScheduler *)scheduler
{
  [_surfaceRegistry enumerateWithBlock:^(NSEnumerator<RSUISurface *> *enumerator) {
    for (RSUISurface *surface in enumerator) {
      [self stopSurface:surface scheduler:scheduler];
    }
  }];
}

- (NSArray<id<RCTSurfacePresenterObserver>> *)_getObservers
{
  NSMutableArray<id<RCTSurfacePresenterObserver>> *observersCopy = [NSMutableArray new];
  for (id<RCTSurfacePresenterObserver> observer : _observers) {
    if (observer) {
      [observersCopy addObject:observer];
    }
  }

  return observersCopy;
}

@end
