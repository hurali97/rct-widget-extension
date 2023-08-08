import React from 'react';

import PlatformBaseViewConfig from 'react-native/Libraries/NativeComponent/PlatformBaseViewConfig';
import { register } from 'react-native/Libraries/Renderer/shims/ReactNativeViewConfigRegistry';

const ButtonNativeComponent = register('RSUIButton', () => {
  return {
    uiViewClassName: 'RSUIButton',
    bubblingEventTypes: {},
    directEventTypes: {
      topPress: {
        registrationName: 'onPress',
      },
      topActiveStateChange: {
        registrationName: 'onActiveStateChange',
      },
    },
    validAttributes: {
      ...PlatformBaseViewConfig.validAttributes,
    },
  };
});

class Button extends React.PureComponent {
  render() {
    return <ButtonNativeComponent {...this.props} />;
  }
}

export default Button;
