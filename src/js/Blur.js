import React from 'react';

import PlatformBaseViewConfig from 'react-native/Libraries/NativeComponent/PlatformBaseViewConfig';
import { register } from 'react-native/Libraries/Renderer/shims/ReactNativeViewConfigRegistry';

const BlurNativeComponent = register('RSUIBlur', () => {
  return {
    uiViewClassName: 'RSUIBlur',
    bubblingEventTypes: {},
    directEventTypes: {},
    validAttributes: {
      ...PlatformBaseViewConfig.validAttributes,
      radius: true,
    },
  };
});

export default class Blur extends React.PureComponent {
  render() {
    return <BlurNativeComponent {...this.props} />;
  }
}
