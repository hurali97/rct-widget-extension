import React from 'react';
import { AppRegistry, StyleSheet } from 'react-native';
import { LinearGradient, Image, View } from 'rct-widget-extension';

const RCTWidget = (props) => {
  return (
    <View
      style={{
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
      }}
      {...props}
    >
      <View style={StyleSheet.absoluteFill}>
        <LinearGradient
          colors={['#A9D710', '#EF8552']}
          from="topLeft"
          to="bottomRight"
        />
      </View>

      <Image
        style={{ width: 40, height: 40 }}
        source={require('./src/assets/react-native.png')}
      />
      <Image
        style={{ width: 40, height: 40 }}
        source={require('./src/assets/swiftui.png')}
      />
    </View>
  );
};

AppRegistry.registerComponent('RCTWidget', () => RCTWidget);
