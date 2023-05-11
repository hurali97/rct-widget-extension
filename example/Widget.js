import React from 'react';
import { AppRegistry } from 'react-native';
import { Rect, LinearGradient } from 'rct-widget-extension';

const RCTWidget = () => {
  return (
    <Rect>
      <LinearGradient
        colors={['#E9D758', '#FF8552']}
        from="topLeft"
        to="bottomRight"
      />
    </Rect>
  );
};

AppRegistry.registerComponent('RCTWidget', () => RCTWidget);
