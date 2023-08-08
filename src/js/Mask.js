import React from 'react';
import { StyleSheet, View } from 'react-native';

import PlatformBaseViewConfig from 'react-native/Libraries/NativeComponent/PlatformBaseViewConfig';
import { register } from 'react-native/Libraries/Renderer/shims/ReactNativeViewConfigRegistry';

const MaskNativeComponent = register('RSUIMask', () => {
  return {
    uiViewClassName: 'RSUIMask',
    bubblingEventTypes: {},
    directEventTypes: {},
    validAttributes: {
      ...PlatformBaseViewConfig.validAttributes,
      shape: true,
    },
  };
});

export default class MaskView extends React.PureComponent {
  render() {
    const { children, shape, ...props } = this.props;

    return (
      <MaskNativeComponent {...props}>
        <View style={StyleSheet.absoluteFill}>{shape}</View>
        {children}
      </MaskNativeComponent>
    );
  }
}
