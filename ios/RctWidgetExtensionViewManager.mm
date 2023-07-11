#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>
#import "RCTBridge.h"

@interface RctWidgetExtensionViewManager : RCTViewManager
@end

@implementation RctWidgetExtensionViewManager

RCT_EXPORT_MODULE(RctWidgetExtensionView)

- (UIView *)view
{
  return [[UIView alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(color, NSString)

@end
