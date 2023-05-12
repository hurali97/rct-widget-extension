import React from 'react';
import { AppRegistry } from 'react-native';
import { Rect, LinearGradient, Image } from 'rct-widget-extension';

const RCTWidget = () => {
  return (
    <Rect>
      <LinearGradient
        colors={['#A9D710', '#EF8552']}
        from="topLeft"
        to="bottomRight"
      />
      <Image
        style={{ width: 40, height: 40, marginTop: -20 }}
        source={require('./src/assets/react-native.png')}
      />
      <Image
        style={{ width: 40, height: 40, marginTop: 5 }}
        source={require('./src/assets/swiftui.png')}
      />
    </Rect>
  );
};

AppRegistry.registerComponent('RCTWidget', () => RCTWidget);
