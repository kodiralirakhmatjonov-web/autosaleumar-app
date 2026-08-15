import { Tabs } from 'expo-router';

export default function WebTabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: '#111111',
        tabBarInactiveTintColor: '#8A8A90',
        tabBarHideOnKeyboard: true,
        tabBarIcon: () => null,
        tabBarStyle: {
          height: 60,
          paddingTop: 8,
          paddingBottom: 8,
          borderTopWidth: 1,
          borderTopColor: 'rgba(60,60,67,0.12)',
          backgroundColor: 'rgba(250,250,252,0.98)',
        },
        tabBarItemStyle: {
          paddingTop: 3,
        },
        tabBarLabelStyle: {
          fontSize: 12,
          lineHeight: 16,
          fontWeight: '600',
        },
      }}
    >
      <Tabs.Screen name="index" options={{ title: 'Главная' }} />
      <Tabs.Screen name="catalog" options={{ title: 'Авто' }} />
      <Tabs.Screen name="saved" options={{ title: 'Избранное' }} />
      <Tabs.Screen name="more" options={{ title: 'Ещё' }} />
      <Tabs.Screen name="page" options={{ href: null }} />
    </Tabs>
  );
}
