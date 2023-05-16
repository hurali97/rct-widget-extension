import React from 'react';
import { View, Text, Image } from 'react-native';

const App = () => {
  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Text>Example</Text>
      <Image
        style={{ width: 40, height: 40 }}
        source={require('./assets/react-native.png')}
      />
    </View>
  );
};

export default App;
