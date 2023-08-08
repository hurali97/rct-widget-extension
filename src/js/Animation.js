import React from 'react';

import PlatformBaseViewConfig from 'react-native/Libraries/NativeComponent/PlatformBaseViewConfig';
import { register } from 'react-native/Libraries/Renderer/shims/ReactNativeViewConfigRegistry';

const AnimationNativeComponent = register('RSUIAnimation', () => {
  return {
    uiViewClassName: 'RSUIAnimation',
    bubblingEventTypes: {},
    directEventTypes: {},
    validAttributes: {
      ...PlatformBaseViewConfig.validAttributes,
      type: true,
      duration: true,
    },
  };
});

export default class Animation extends React.PureComponent {
  render() {
    return <AnimationNativeComponent {...this.props} />;
  }
}
