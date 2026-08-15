import { Tabs } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import type { ComponentProps } from 'react';
const style={position:'absolute',left:14,right:14,bottom:10,height:72,paddingTop:7,paddingBottom:7,borderTopWidth:0,borderWidth:1,borderColor:'rgba(255,255,255,.74)',borderRadius:36,backgroundColor:'rgba(246,246,244,.58)',boxShadow:'0 14px 44px rgba(0,0,0,.14)',backdropFilter:'blur(34px) saturate(190%)',WebkitBackdropFilter:'blur(34px) saturate(190%)'} as const;
function Icon({name,color}:{name:ComponentProps<typeof SymbolView>['name'];color:string}){return <SymbolView name={name} size={22} tintColor={color} weight="semibold"/>}
export default function Layout(){return <Tabs screenOptions={{headerShown:false,tabBarActiveTintColor:'#111214',tabBarInactiveTintColor:'#8E8E93',tabBarStyle:style as never,tabBarItemStyle:{borderRadius:28},tabBarLabelStyle:{fontSize:10.5,lineHeight:13,fontWeight:'600',marginTop:1}}}>
<Tabs.Screen name="index" options={{title:'Главная',tabBarIcon:({focused,color})=><Icon color={color} name={{ios:focused?'house.fill':'house',android:'home',web:'home'}}/>}}/>
<Tabs.Screen name="catalog" options={{title:'Автомобили',tabBarIcon:({focused,color})=><Icon color={color} name={{ios:focused?'car.fill':'car',android:'directions_car',web:'directions_car'}}/>}}/>
<Tabs.Screen name="saved" options={{title:'Избранное',tabBarIcon:({focused,color})=><Icon color={color} name={{ios:focused?'heart.fill':'heart',android:'favorite',web:'favorite'}}/>}}/>
<Tabs.Screen name="profile" options={{title:'Настройки',tabBarIcon:({focused,color})=><Icon color={color} name={{ios:focused?'gearshape.fill':'gearshape',android:'settings',web:'settings'}}/>}}/>
<Tabs.Screen name="more" options={{href:null}}/><Tabs.Screen name="page" options={{href:null}}/></Tabs>}
