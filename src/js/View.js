import React from 'react';

import * as ReactNativeViewViewConfig from 'react-native/Libraries/Components/View/ReactNativeViewViewConfig';
import { register } from 'react-native/Libraries/Renderer/shims/ReactNativeViewConfigRegistry';

const ViewNativeComponent = register('RSUIBaseView', () => {
  return {
    uiViewClassName: 'RSUIBaseView',
    bubblingEventTypes: {},
    directEventTypes: {},
    validAttributes: {
      ...ReactNativeViewViewConfig.validAttributes,
    },
  };
});

class View extends React.PureComponent {
  render() {
    return <ViewNativeComponent {...this.props} />;
  }
}

export default View;
