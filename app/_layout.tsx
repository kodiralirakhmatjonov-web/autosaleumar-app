import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useColorScheme } from 'react-native';
import { AppProvider } from '@/src/state/AppProvider';

export default function RootLayout(){const dark=useColorScheme()==='dark';return <AppProvider><StatusBar style={dark?'light':'dark'}/><Stack screenOptions={{headerShown:false,animation:'default'}}><Stack.Screen name="(tabs)"/><Stack.Screen name="car/[slug]"/><Stack.Screen name="request-car"/><Stack.Screen name="booking"/><Stack.Screen name="location"/><Stack.Screen name="showroom"/><Stack.Screen name="contacts"/><Stack.Screen name="compare"/><Stack.Screen name="trust"/><Stack.Screen name="admin/cars"/><Stack.Screen name="admin/car-new"/><Stack.Screen name="admin/car-edit"/><Stack.Screen name="admin/car-media"/><Stack.Screen name="admin/staff"/><Stack.Screen name="admin/visits"/><Stack.Screen name="admin/requests"/><Stack.Screen name="admin/brands"/><Stack.Screen name="admin/home-media"/></Stack></AppProvider>}
