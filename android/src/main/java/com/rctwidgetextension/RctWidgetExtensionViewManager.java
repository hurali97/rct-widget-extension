package com.rctwidgetextension;

import android.graphics.Color;

import androidx.annotation.Nullable;

import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewManagerDelegate;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.viewmanagers.RctWidgetExtensionViewManagerDelegate;
import com.facebook.react.viewmanagers.RctWidgetExtensionViewManagerInterface;
import com.facebook.soloader.SoLoader;

@ReactModule(name = RctWidgetExtensionViewManager.NAME)
public class RctWidgetExtensionViewManager extends SimpleViewManager<RctWidgetExtensionView> implements RctWidgetExtensionViewManagerInterface<RctWidgetExtensionView> {

  public static final String NAME = "RctWidgetExtensionView";

  static {
    if (BuildConfig.CODEGEN_MODULE_REGISTRATION != null) {
      SoLoader.loadLibrary(BuildConfig.CODEGEN_MODULE_REGISTRATION);
    }
  }

  private final ViewManagerDelegate<RctWidgetExtensionView> mDelegate;

  public RctWidgetExtensionViewManager() {
    mDelegate = new RctWidgetExtensionViewManagerDelegate(this);
  }

  @Nullable
  @Override
  protected ViewManagerDelegate<RctWidgetExtensionView> getDelegate() {
    return mDelegate;
  }

  @Override
  public String getName() {
    return NAME;
  }

  @Override
  public RctWidgetExtensionView createViewInstance(ThemedReactContext context) {
    return new RctWidgetExtensionView(context);
  }

  @Override
  @ReactProp(name = "color")
  public void setColor(RctWidgetExtensionView view, String color) {
    view.setBackgroundColor(Color.parseColor(color));
  }
}
