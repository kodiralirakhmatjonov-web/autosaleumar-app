import { Tabs } from 'expo-router';

export default function WebTabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: '#111111',
        tabBarInactiveTintColor: '#7A7A80',
        tabBarStyle: {
          height: 70,
          paddingTop: 8,
          paddingBottom: 10,
          borderTopWidth: 1,
          borderTopColor: 'rgba(60,60,67,0.12)',
          backgroundColor: 'rgba(250,250,252,0.96)',
        },
        tabBarLabelStyle: { fontSize: 12, fontWeight: '600' },
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
