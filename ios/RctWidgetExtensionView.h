// This guard prevent this file to be compiled in the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef RctWidgetExtensionViewNativeComponent_h
#define RctWidgetExtensionViewNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface RctWidgetExtensionView : RCTViewComponentView
@end

NS_ASSUME_NONNULL_END

#endif /* RctWidgetExtensionViewNativeComponent_h */
#endif /* RCT_NEW_ARCH_ENABLED */
