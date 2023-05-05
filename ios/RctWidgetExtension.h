
#ifdef RCT_NEW_ARCH_ENABLED
#import "RNRctWidgetExtensionSpec.h"

@interface RctWidgetExtension : NSObject <NativeRctWidgetExtensionSpec>
#else
#import <React/RCTBridgeModule.h>

@interface RctWidgetExtension : NSObject <RCTBridgeModule>
#endif

@end
