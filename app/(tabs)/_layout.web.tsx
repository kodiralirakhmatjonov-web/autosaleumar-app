import { Tabs } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import type { ComponentProps } from 'react';

const glassTabBarStyle = {
  position: 'absolute',
  left: 14,
  right: 14,
  bottom: 10,
  height: 70,
  paddingTop: 7,
  paddingBottom: 7,
  borderTopWidth: 0,
  borderWidth: 1,
  borderColor: 'rgba(255,255,255,0.72)',
  borderRadius: 35,
  backgroundColor: 'rgba(248,248,250,0.78)',
  boxShadow: '0 14px 42px rgba(0,0,0,0.13), inset 0 0 0 0.5px rgba(0,0,0,0.05)',
  backdropFilter: 'blur(28px) saturate(180%)',
  WebkitBackdropFilter: 'blur(28px) saturate(180%)',
} as const;

function TabIcon({
  name,
  color,
}: {
  name: ComponentProps<typeof SymbolView>['name'];
  color: string;
}) {
  return <SymbolView name={name} size={21} tintColor={color} weight="semibold" />;
}

export default function WebTabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: '#111111',
        tabBarInactiveTintColor: '#8E8E93',
        tabBarHideOnKeyboard: true,
        tabBarStyle: glassTabBarStyle as never,
        tabBarItemStyle: { borderRadius: 26, paddingTop: 2 },
        tabBarLabelStyle: { fontSize: 10.5, lineHeight: 13, fontWeight: '600', marginTop: 1 },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Главная',
          tabBarIcon: ({ focused, color }) => <TabIcon name={{ ios: focused ? 'house.fill' : 'house', android: 'home', web: 'home' }} color={color} />,
        }}
      />
      <Tabs.Screen
        name="catalog"
        options={{
          title: 'Авто',
          tabBarIcon: ({ focused, color }) => <TabIcon name={{ ios: focused ? 'car.fill' : 'car', android: 'directions_car', web: 'directions_car' }} color={color} />,
        }}
      />
      <Tabs.Screen
        name="saved"
        options={{
          title: 'Избранное',
          tabBarIcon: ({ focused, color }) => <TabIcon name={{ ios: focused ? 'heart.fill' : 'heart', android: 'favorite', web: 'favorite' }} color={color} />,
        }}
      />
      <Tabs.Screen
        name="more"
        options={{
          title: 'Ещё',
          tabBarIcon: ({ focused, color }) => <TabIcon name={{ ios: 'ellipsis', android: 'more_horiz', web: 'more_horiz' }} color={color} />,
        }}
      />
      <Tabs.Screen name="page" options={{ href: null }} />
    </Tabs>
  );
}
