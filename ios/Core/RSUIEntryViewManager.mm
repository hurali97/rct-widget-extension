
#import <cxxreact/JSExecutor.h>
#import <ReactCommon/RCTTurboModuleManager.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTCxxBridgeDelegate.h>
#import <reacthermes/HermesExecutorFactory.h>
#import <React/RCTImageLoader.h>
#import <React/RCTLocalAssetImageLoader.h>
#import <React/RCTGIFImageDecoder.h>
#import <React/RCTNetworking.h>
#import <React/RCTHTTPRequestHandler.h>
#import <React/RCTDataRequestHandler.h>
#import <React/RCTFileRequestHandler.h>

#import <React/CoreModulesPlugins.h>
#import <ReactCommon/SampleTurboCxxModule.h>
#import <react/renderer/runtimescheduler/RuntimeScheduler.h>
#import <React/RCTRuntimeExecutorFromBridge.h>
#import <react/renderer/runtimescheduler/RuntimeSchedulerCallInvoker.h>
#import <React/RCTJSIExecutorRuntimeInstaller.h>
#import <react/renderer/runtimescheduler/RuntimeSchedulerBinding.h>

#import "RSUIEntryViewManager.h"

#pragma mark - TurboModule provider

Class RSUITurboModuleClassProvider(const char *name) {
  return RCTCoreModulesClassProvider(name);
}

std::shared_ptr<facebook::react::TurboModule> RSUITurboModuleProvider(const std::string &name, std::shared_ptr<facebook::react::CallInvoker> jsInvoker) {
  return nullptr;
}

std::shared_ptr<facebook::react::TurboModule> RSUITurboModuleProvider(const std::string &name, const facebook::react::ObjCTurboModule::InitParams &params) {
  return nullptr;
}

#pragma mark - Entry view manager

@interface RSUIEntryViewManagerObjC() <RCTCxxBridgeDelegate, RCTTurboModuleManagerDelegate> {
    std::shared_ptr<facebook::react::RuntimeScheduler> _runtimeScheduler;
}
@end

@implementation RSUIEntryViewManagerObjC {
  NSString *_bundlePath;
  RCTBridge *_bridge;
  RCTTurboModuleManager *_turboModuleManager;
}

- (instancetype)initWithModuleName:(NSString *)moduleName bundlePath:(NSString *)bundlePath
{
  if (self = [super init]) {
    _bundlePath = bundlePath;
    _bridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:nil];
    _appContext = [[RSUIAppContext alloc] initWithBridge:_bridge moduleName:moduleName initialProperties:@{}];
    [_appContext.surface start];
  }
  return self;
}

- (NSInteger)surfaceTag
{
  return _appContext.surface.rootTag;
}

- (BOOL)runtimeSchedulerEnabled
{
  return YES;
}

# pragma mark - RCTCxxBridgeDelegate

- (NSURL *)sourceURLForBridge:(__unused RCTBridge *)bridge
{
  #if DEBUG
    return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:_bundlePath];
  #else
    return [[NSBundle mainBundle] URLForResource:@"widget" withExtension:@"jsbundle"];
  #endif
}

- (std::unique_ptr<facebook::react::JSExecutorFactory>)jsExecutorFactoryForBridge:(RCTBridge *)bridge
{
  _runtimeScheduler = std::make_shared<facebook::react::RuntimeScheduler>(RCTRuntimeExecutorFromBridge(bridge));
  std::shared_ptr<facebook::react::CallInvoker> callInvoker =
      std::make_shared<facebook::react::RuntimeSchedulerCallInvoker>(_runtimeScheduler);
  _turboModuleManager = [[RCTTurboModuleManager alloc] initWithBridge:bridge delegate:self jsInvoker:callInvoker];

    // Necessary to allow NativeModules to lookup TurboModules
    [bridge setRCTTurboModuleRegistry:_turboModuleManager];

  #if RCT_DEV
    if (!RCTTurboModuleEagerInitEnabled()) {
      /**
       * Instantiating DevMenu has the side-effect of registering
       * shortcuts for CMD + d, CMD + i,  and CMD + n via RCTDevMenu.
       * Therefore, when TurboModules are enabled, we must manually create this
       * NativeModule.
       */
      [_turboModuleManager moduleForName:"RCTDevMenu"];
    }
  #endif
    
    RCTTurboModuleManager *turboModuleManager = _turboModuleManager;
    std::shared_ptr<facebook::react::RuntimeScheduler> const &runtimeScheduler = _runtimeScheduler;
    
  return std::make_unique<facebook::react::HermesExecutorFactory>(
    facebook::react::RCTJSIExecutorRuntimeInstaller(
        [turboModuleManager, bridge, runtimeScheduler](facebook::jsi::Runtime &runtime) {
          if (!bridge || !turboModuleManager) {
            return;
          }
          if (runtimeScheduler) {
            facebook::react::RuntimeSchedulerBinding::createAndInstallIfNeeded(runtime, runtimeScheduler);
          }
          facebook::react::RuntimeExecutor syncRuntimeExecutor =
              [&](std::function<void(facebook::jsi::Runtime & runtime_)> &&callback) { callback(runtime); };
          [turboModuleManager installJSBindingWithRuntimeExecutor:syncRuntimeExecutor];
        }));
}

#pragma mark RCTTurboModuleManagerDelegate

- (Class)getModuleClassFromName:(const char *)name
{
  return RSUITurboModuleClassProvider(name);
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name
                                                      jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)jsInvoker
{
  return RSUITurboModuleProvider(name, jsInvoker);
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name
                                                       initParams:(const facebook::react::ObjCTurboModule::InitParams &)params
{
  return RSUITurboModuleProvider(name, params);
}

- (id<RCTTurboModule>)getModuleInstanceFromClass:(Class)moduleClass
{
  if (moduleClass == RCTImageLoader.class) {
    return [[moduleClass alloc] initWithRedirectDelegate:nil
        loadersProvider:^NSArray<id<RCTImageURLLoader>> *(RCTModuleRegistry *moduleRegistry) {
          return @[ [RCTLocalAssetImageLoader new] ];
        }
        decodersProvider:^NSArray<id<RCTImageDataDecoder>> *(RCTModuleRegistry *moduleRegistry) {
          return @[ [RCTGIFImageDecoder new] ];
        }];
  } else if (moduleClass == RCTNetworking.class) {
    return [[moduleClass alloc]
      initWithHandlersProvider:^NSArray<id<RCTURLRequestHandler>> *(RCTModuleRegistry *moduleRegistry) {
        return @[
          [RCTHTTPRequestHandler new],
          [RCTDataRequestHandler new],
          [RCTFileRequestHandler new],
        ];
      }];
  }
  // No custom initializer here.
  return [moduleClass new];
}

#pragma mark - New Arch Enabled settings

- (BOOL)turboModuleEnabled
{
  return YES;
}

- (BOOL)fabricEnabled
{
  return YES;
}

@end
