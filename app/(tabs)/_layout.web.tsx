import { Tabs } from 'expo-router';
import { SymbolView } from 'expo-symbols';

export default function WebTabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: '#111111',
        tabBarInactiveTintColor: '#7A7A80',
        tabBarStyle: {
          height: 68,
          paddingTop: 8,
          paddingBottom: 9,
          borderTopWidth: 1,
          borderTopColor: 'rgba(60,60,67,0.12)',
          backgroundColor: 'rgba(250,250,252,0.97)',
        },
        tabBarLabelStyle: { fontSize: 11, fontWeight: '600' },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Главная',
          tabBarIcon: ({ color, size }) => (
            <SymbolView name={{ ios: 'house', android: 'home', web: 'home' }} tintColor={color} size={Math.min(size, 22)} />
          ),
        }}
      />
      <Tabs.Screen
        name="catalog"
        options={{
          title: 'Авто',
          tabBarIcon: ({ color, size }) => (
            <SymbolView name={{ ios: 'car', android: 'directions_car', web: 'directions_car' }} tintColor={color} size={Math.min(size, 22)} />
          ),
        }}
      />
      <Tabs.Screen
        name="saved"
        options={{
          title: 'Избранное',
          tabBarIcon: ({ color, size }) => (
            <SymbolView name={{ ios: 'heart', android: 'favorite', web: 'favorite' }} tintColor={color} size={Math.min(size, 22)} />
          ),
        }}
      />
      <Tabs.Screen
        name="more"
        options={{
          title: 'Ещё',
          tabBarIcon: ({ color, size }) => (
            <SymbolView name={{ ios: 'ellipsis', android: 'more_horiz', web: 'more_horiz' }} tintColor={color} size={Math.min(size, 22)} />
          ),
        }}
      />
      <Tabs.Screen name="page" options={{ href: null }} />
    </Tabs>
  );
}
