import React from 'react';

import PlatformBaseViewConfig from 'react-native/Libraries/NativeComponent/PlatformBaseViewConfig';
import { register } from 'react-native/Libraries/Renderer/shims/ReactNativeViewConfigRegistry';
import resolveAssetSource from 'react-native/Libraries/Image/resolveAssetSource';

const ImageNativeComponent = register('RSUIImage', () => {
  return {
    uiViewClassName: 'RSUIImage',
    bubblingEventTypes: {},
    directEventTypes: {},
    validAttributes: {
      ...PlatformBaseViewConfig.validAttributes,
      source: true,
    },
  };
});

export default class Image extends React.PureComponent {
  render() {
    const source = resolveAssetSource(this.props.source) || {};
    const sources = Array.isArray(source) ? source : [source];

    return <ImageNativeComponent {...this.props} source={sources} />;
  }
}
