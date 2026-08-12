import { Icon } from 'expo-router';
import { NativeTabs } from 'expo-router/unstable-native-tabs';

export default function TabLayout() {
  return (
    <NativeTabs minimizeBehavior="onScrollDown">
      <NativeTabs.Trigger name="index">
        <NativeTabs.Trigger.Icon><Icon sf={{ default: 'house', selected: 'house.fill' }} /></NativeTabs.Trigger.Icon>
        <NativeTabs.Trigger.Label>Главная</NativeTabs.Trigger.Label>
      </NativeTabs.Trigger>
      <NativeTabs.Trigger name="catalog">
        <NativeTabs.Trigger.Icon><Icon sf={{ default: 'car', selected: 'car.fill' }} /></NativeTabs.Trigger.Icon>
        <NativeTabs.Trigger.Label>Авто</NativeTabs.Trigger.Label>
      </NativeTabs.Trigger>
      <NativeTabs.Trigger name="saved">
        <NativeTabs.Trigger.Icon><Icon sf={{ default: 'heart', selected: 'heart.fill' }} /></NativeTabs.Trigger.Icon>
        <NativeTabs.Trigger.Label>Избранное</NativeTabs.Trigger.Label>
      </NativeTabs.Trigger>
      <NativeTabs.Trigger name="more">
        <NativeTabs.Trigger.Icon><Icon sf="ellipsis" /></NativeTabs.Trigger.Icon>
        <NativeTabs.Trigger.Label>Ещё</NativeTabs.Trigger.Label>
      </NativeTabs.Trigger>
    </NativeTabs>
  );
}
