import { NativeTabs } from 'expo-router/unstable-native-tabs';
import { DynamicColorIOS, Platform } from 'react-native';
const tintColor=Platform.OS==='ios'?DynamicColorIOS({dark:'#FFFFFF',light:'#111214'}):'#111214';
export default function TabLayout(){return <NativeTabs blurEffect="systemDefault" minimizeBehavior="onScrollDown" tintColor={tintColor} labelStyle={{color:tintColor}}>
 <NativeTabs.Trigger name="index"><NativeTabs.Trigger.Icon sf={{default:'house',selected:'house.fill'}} md="home"/><NativeTabs.Trigger.Label>Главная</NativeTabs.Trigger.Label></NativeTabs.Trigger>
 <NativeTabs.Trigger name="catalog"><NativeTabs.Trigger.Icon sf={{default:'car',selected:'car.fill'}} md="directions_car"/><NativeTabs.Trigger.Label>Автомобили</NativeTabs.Trigger.Label></NativeTabs.Trigger>
 <NativeTabs.Trigger name="saved"><NativeTabs.Trigger.Icon sf={{default:'heart',selected:'heart.fill'}} md="favorite"/><NativeTabs.Trigger.Label>Избранное</NativeTabs.Trigger.Label></NativeTabs.Trigger>
 <NativeTabs.Trigger name="profile"><NativeTabs.Trigger.Icon sf={{default:'person.crop.circle',selected:'person.crop.circle.fill'}} md="account_circle"/><NativeTabs.Trigger.Label>Профиль</NativeTabs.Trigger.Label></NativeTabs.Trigger>
 </NativeTabs>}
