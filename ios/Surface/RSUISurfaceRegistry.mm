
#import <mutex>
#import <shared_mutex>

#import "RSUISurface.h"
#import "RSUISurfaceRegistry.h"

// To provide namespace facebook
#import <react/renderer/scheduler/SurfaceHandler.h>

using namespace facebook;

@implementation RSUISurfaceRegistry {
  std::shared_mutex _mutex;
  NSMapTable<id, RSUISurface *> *_registry;
}

- (instancetype)init
{
  if (self = [super init]) {
    _registry = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsIntegerPersonality | NSPointerFunctionsOpaqueMemory
                                      valueOptions:NSPointerFunctionsObjectPersonality | NSPointerFunctionsWeakMemory];
  }

  return self;
}

- (void)enumerateWithBlock:(RSUISurfaceEnumeratorBlock)block
{
  std::shared_lock lock(_mutex);
  block([_registry objectEnumerator]);
}

- (void)registerSurface:(RSUISurface *)surface
{
  std::unique_lock lock(_mutex);

  ReactTag rootTag = surface.rootViewTag.integerValue;
  [_registry setObject:surface forKey:(__bridge id)(void *)rootTag];
}

- (void)unregisterSurface:(RSUISurface *)surface
{
  std::unique_lock lock(_mutex);

  ReactTag rootTag = surface.rootViewTag.integerValue;
  [_registry removeObjectForKey:(__bridge id)(void *)rootTag];
}

- (RSUISurface *)surfaceForRootTag:(ReactTag)rootTag
{
  std::shared_lock lock(_mutex);

  return [_registry objectForKey:(__bridge id)(void *)rootTag];
}

@end
