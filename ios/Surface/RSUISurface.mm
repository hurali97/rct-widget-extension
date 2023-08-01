
#import <mutex>

#import <React/RCTSurfaceDelegate.h>
#import <React/RCTSurfaceView+Internal.h>
#import <React/RCTUIManagerUtils.h>
#import <React/RCTUtils.h>
#import <React/RCTFollyConvert.h>
#import <React/RCTI18nUtil.h>

#import "RSUISurface.h"
#import "RSUISurfaceView.h"
#import "RSUISurfacePresenter.h"
#import "RSUIConversions.h"
#import "RSUIMountingManager.h"

@implementation RSUISurface {
    __weak RSUISurfacePresenter *_surfacePresenter;
    
  // `SurfaceHandler` is a thread-safe object, so we don't need additional synchronization.
  // Objective-C++ classes cannot have instance variables without default constructors,
  // hence we wrap a value into `optional` to workaround it.
  std::optional<SurfaceHandler> _surfaceHandler;

  // Protects Surface's start and stop processes.
  // Even though SurfaceHandler is tread-safe, it will crash if we try to stop a surface that is not running.
  // To make the API easy to use, we check the status of the surface before calling `start` or `stop`,
  // and we need this mutex to prevent races.
  std::mutex _surfaceMutex;

  // Can be accessed from the main thread only.
  RSUISurfaceView *_Nullable _view;
}

@synthesize delegate = _delegate;

- (instancetype)initWithSurfacePresenter:(RSUISurfacePresenter *)surfacePresenter
                              moduleName:(NSString *)moduleName
                       initialProperties:(NSDictionary *)initialProperties
{
  if (self = [super init]) {
    _surfacePresenter = surfacePresenter;
    _surfaceHandler =
          SurfaceHandler{RCTStringFromNSString(moduleName), (SurfaceId)[RCTAllocateRootViewTag() integerValue]};
      _surfaceHandler->setProps(convertIdToFollyDynamic(initialProperties));
      
    [_surfacePresenter registerSurface:self];
      
    [self setMinimumSize:CGSizeZero maximumSize:RCTViewportSize()];

    [self _updateLayoutContext];
      
    [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(handleContentSizeCategoryDidChangeNotification:)
                                                   name:UIContentSizeCategoryDidChangeNotification
                                                 object:nil];
  }
  return self;
}

- (void)dealloc
{
  [self stop];
}

#pragma mark - Immutable Properties (no need to enforce synchronization)

- (NSString *)moduleName
{
  return RCTNSStringFromString(_surfaceHandler->getModuleName());
}

#pragma mark - Main-Threaded Routines

- (nonnull RSUISurfaceView *)view
{
#if !TARGET_OS_OSX
  RCTAssertMainQueue();

  if (!_view) {
    _view = [[RSUISurfaceView alloc] initWithSurface:(RCTSurface *)self viewRegistry:_surfacePresenter.viewRegistry];
  }
#endif
  return _view;
}

#pragma mark - Life-cycle management

- (void)start
{
  std::lock_guard<std::mutex> lock(_surfaceMutex);

  if (_surfaceHandler->getStatus() != SurfaceHandler::Status::Registered) {
    return;
  }

  // We need to register a root view component here synchronously because right after
  // we start a surface, it can initiate an update that can query the root component.
  RCTUnsafeExecuteOnMainQueueSync(^{
    [self->_surfacePresenter.mountingManager attachSurfaceToView:self.view
                                                       surfaceId:self->_surfaceHandler->getSurfaceId()];
  });
  [_surfacePresenter registerSurface:self];
  _surfaceHandler->start();
  [self _propagateStageChange];

//  [_surfacePresenter setupAnimationDriverWithSurfaceHandler:*_surfaceHandler];
}

- (void)stop
{
  std::lock_guard<std::mutex> lock(_surfaceMutex);

  if (_surfaceHandler->getStatus() != SurfaceHandler::Status::Running) {
    return;
  }

  _surfaceHandler->stop();
  [self _propagateStageChange];

  [_surfacePresenter unregisterSurface:self];
  RCTExecuteOnMainQueue(^{
    [self->_surfacePresenter.mountingManager detachSurfaceFromView:self.view
                                                         surfaceId:self->_surfaceHandler->getSurfaceId()];
  });
}

#pragma mark - Stage management

- (RCTSurfaceStage)stage
{
  return _surfaceHandler->getStatus() == SurfaceHandler::Status::Running ? RCTSurfaceStageRunning
                                                                         : RCTSurfaceStagePreparing;
}

- (void)_propagateStageChange
{
  RCTSurfaceStage stage = self.stage;

  // Notifying the `delegate`
  id<RCTSurfaceDelegate> delegate = self.delegate;
  if ([delegate respondsToSelector:@selector(surface:didChangeStage:)]) {
    [delegate surface:(RCTSurface *)self didChangeStage:stage];
  }
}

- (void)_updateLayoutContext
{
  auto layoutConstraints = _surfaceHandler->getLayoutConstraints();
  layoutConstraints.layoutDirection = RCTLayoutDirection([[RCTI18nUtil sharedInstance] isRTL]);

  auto layoutContext = _surfaceHandler->getLayoutContext();

  layoutContext.pointScaleFactor = RCTScreenScale();
  layoutContext.swapLeftAndRightInRTL =
      [[RCTI18nUtil sharedInstance] isRTL] && [[RCTI18nUtil sharedInstance] doLeftAndRightSwapInRTL];
  layoutContext.fontSizeMultiplier = RCTFontSizeMultiplier();

  _surfaceHandler->constraintLayout(layoutConstraints, layoutContext);
}

#pragma mark - Properties management

- (NSDictionary *)properties
{
  return convertFollyDynamicToId(_surfaceHandler->getProps());
}

- (void)setProperties:(NSDictionary *)properties
{
  _surfaceHandler->setProps(convertIdToFollyDynamic(properties));
}

#pragma mark - Layout

- (void)setMinimumSize:(CGSize)minimumSize maximumSize:(CGSize)maximumSize viewportOffset:(CGPoint)viewportOffset
{
  auto layoutConstraints = _surfaceHandler->getLayoutConstraints();
  auto layoutContext = _surfaceHandler->getLayoutContext();

  layoutConstraints.minimumSize = RCTSizeFromCGSize(minimumSize);
  layoutConstraints.maximumSize = RCTSizeFromCGSize(maximumSize);

  if (!isnan(viewportOffset.x) && !isnan(viewportOffset.y)) {
    layoutContext.viewportOffset = RCTPointFromCGPoint(viewportOffset);
  }

  _surfaceHandler->constraintLayout(layoutConstraints, layoutContext);
}

- (void)setMinimumSize:(CGSize)minimumSize maximumSize:(CGSize)maximumSize
{
  [self setMinimumSize:minimumSize maximumSize:maximumSize viewportOffset:CGPointMake(NAN, NAN)];
}

- (void)setSize:(CGSize)size
{
  [self setMinimumSize:size maximumSize:size];
}

- (CGSize)sizeThatFitsMinimumSize:(CGSize)minimumSize maximumSize:(CGSize)maximumSize
{
  auto layoutConstraints = _surfaceHandler->getLayoutConstraints();
  auto layoutContext = _surfaceHandler->getLayoutContext();

  layoutConstraints.minimumSize = RCTSizeFromCGSize(minimumSize);
  layoutConstraints.maximumSize = RCTSizeFromCGSize(maximumSize);

  return RCTCGSizeFromSize(_surfaceHandler->measure(layoutConstraints, layoutContext));
}

- (CGSize)minimumSize
{
  return RCTCGSizeFromSize(_surfaceHandler->getLayoutConstraints().minimumSize);
}

- (CGSize)maximumSize
{
  return RCTCGSizeFromSize(_surfaceHandler->getLayoutConstraints().maximumSize);
}

- (CGPoint)viewportOffset
{
  return RCTCGPointFromPoint(_surfaceHandler->getLayoutContext().viewportOffset);
}

#pragma mark - Synchronous Waiting

- (BOOL)synchronouslyWaitFor:(NSTimeInterval)timeout
{
  auto mountingCoordinator = _surfaceHandler->getMountingCoordinator();

  if (!mountingCoordinator) {
    return NO;
  }

  if (!mountingCoordinator->waitForTransaction(std::chrono::duration<NSTimeInterval>(timeout))) {
    return NO;
  }

  [_surfacePresenter.mountingManager scheduleTransaction:mountingCoordinator];

  return YES;
}

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification *)notification
{
  [self _updateLayoutContext];
}

#pragma mark - Private

- (SurfaceHandler const &)surfaceHandler;
{
  return *_surfaceHandler;
}

- (NSNumber *)rootViewTag
{
  return @(_surfaceHandler->getSurfaceId());
}

- (NSInteger)rootTag
{
  return (NSInteger)(_surfaceHandler->getSurfaceId());
}

@end
