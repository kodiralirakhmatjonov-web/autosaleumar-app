import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useColorScheme } from 'react-native';

export default function RootLayout() {
  const dark = useColorScheme() === 'dark';
  return (
    <>
      <StatusBar style={dark ? 'light' : 'dark'} />
      <Stack screenOptions={{ animation: 'default' }}>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen
          name="car/[slug]"
          options={{
            headerShown: true,
            headerTitle: '',
            headerTransparent: true,
            headerShadowVisible: false,
          }}
        />
      </Stack>
    </>
  );
}
