import React from 'react';
import { processColor, StyleSheet } from 'react-native';

import PlatformBaseViewConfig from 'react-native/Libraries/NativeComponent/PlatformBaseViewConfig';
import { register } from 'react-native/Libraries/Renderer/shims/ReactNativeViewConfigRegistry';

const CircleNativeComponent = register('RSUICircle', () => {
  return {
    uiViewClassName: 'RSUICircle',
    bubblingEventTypes: {},
    directEventTypes: {},
    validAttributes: {
      ...PlatformBaseViewConfig.validAttributes,
      fill: { process: processColor },
      stroke: { process: processColor },
      strokeWidth: true,
      strokeDashes: true,
      strokeDashPhase: true,
      strokeLineCap: true,
      strokeLineJoin: true,
      offsetX: true,
      offsetY: true,
      radius: true,
      alignment: true,
    },
  };
});

export default class ShadowView extends React.PureComponent {
  render() {
    return (
      <CircleNativeComponent {...this.props} style={StyleSheet.absoluteFill} />
    );
  }
}
