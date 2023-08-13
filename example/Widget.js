import React from 'react';
/**
 * We can re-use Image, Text, View from react-native.
 * As far as I understand, their underlying names like
 * RCTText, RCTImage, RCTView are registered in the
 * ReactNativeViewConfigRegistry. So for example, in our
 * RSUIBaseView we have defined "View" as the name, which is
 * then subsituted with RCTView.
 */
import { AppRegistry, StyleSheet, View, Text, Image } from 'react-native';
import { LinearGradient, Shadow } from 'rct-widget-extension';

const RCTWidget = (props) => {
  return (
    <View
      style={{
        flex: 1,
        justifyContent: 'center',
      }}
    >
      <View style={StyleSheet.absoluteFill}>
        <LinearGradient
          colors={['#A9D710', '#EF8552']}
          from="topLeft"
          to="bottomRight"
        />
      </View>

      <Shadow radius={3} offsetX={3} offsetY={3} color="black">
        <Text
          style={{
            color: 'black',
            fontSize: 15,
            fontWeight: 'bold',
            textAlign: 'center',
          }}
        >
          SwiftUI Widget
        </Text>
      </Shadow>
      <View
        style={{
          justifyContent: 'center',
          alignItems: 'center',
        }}
      >
        <Image
          style={{ width: 40, height: 40 }}
          source={require('./src/assets/react-native.png')}
        />
        <Image
          style={{ width: 40, height: 40 }}
          source={require('./src/assets/swiftui.png')}
        />
      </View>
    </View>
  );
};

AppRegistry.registerComponent('RCTWidget', () => RCTWidget);
