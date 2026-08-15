import { router } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import type { PropsWithChildren } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View, useColorScheme, type ScrollViewProps } from 'react-native';
import { Image } from 'expo-image';
import { SiteGlass } from './SiteGlass';
import { siteAssets } from '@/src/site/assets';
import { useApp } from '@/src/state/AppProvider';
import { colors } from '@/src/theme/colors';

export function AdminShell({title,subtitle,children,scrollProps}:{title:string;subtitle?:string;children:React.ReactNode;scrollProps?:ScrollViewProps}){
 const dark=useColorScheme()==='dark';const p=colors[dark?'dark':'light'];const {user,token}=useApp();
 if(!user||!token)return <View style={[s.locked,{backgroundColor:p.background}]}><SymbolView name={{ios:'lock.fill',android:'lock',web:'lock'}} size={28} tintColor={p.secondary}/><Text style={[s.lockedTitle,{color:p.text}]}>Требуется вход</Text><Pressable onPress={()=>router.replace('/(tabs)/profile')} style={[s.lockedBtn,{backgroundColor:p.text}]}><Text style={[s.lockedBtnText,{color:p.background}]}>Открыть профиль</Text></Pressable></View>;
 return <View style={[s.page,{backgroundColor:p.background}]}><ScrollView contentContainerStyle={s.content} {...scrollProps}><View style={s.shell}><View style={s.top}><Pressable onPress={()=>router.back()}><SiteGlass interactive style={s.round}><SymbolView name={{ios:'chevron.left',android:'arrow_back',web:'arrow_back'}} size={19} tintColor={p.text}/></SiteGlass></Pressable><Image source={dark?siteAssets.wordmarkWhite:siteAssets.wordmarkBlack} style={s.logo} contentFit="contain"/><Pressable onPress={()=>router.replace('/(tabs)/profile')}><SiteGlass interactive style={s.round}><SymbolView name={{ios:'person.crop.circle.fill',android:'account_circle',web:'account_circle'}} size={20} tintColor={p.text}/></SiteGlass></Pressable></View><Text style={[s.controlLabel,{color:p.secondary}]}>AUTO SALE UMAR · CONTROL SYSTEM</Text><Text style={[s.title,{color:p.text}]}>{title}</Text>{subtitle?<Text style={[s.subtitle,{color:p.secondary}]}>{subtitle}</Text>:null}{children}</View></ScrollView></View>
}
const s=StyleSheet.create({page:{flex:1},content:{paddingBottom:90},shell:{width:'100%',maxWidth:760,alignSelf:'center',paddingHorizontal:16},top:{height:62,flexDirection:'row',alignItems:'center',justifyContent:'space-between'},round:{width:42,height:42,borderRadius:21,alignItems:'center',justifyContent:'center'},logo:{width:150,height:32},controlLabel:{marginTop:20,fontSize:9,lineHeight:12,fontWeight:'700',letterSpacing:1.7},title:{marginTop:7,fontSize:38,lineHeight:42,fontWeight:'700',letterSpacing:-1.4},subtitle:{marginTop:8,fontSize:14,lineHeight:21},locked:{flex:1,alignItems:'center',justifyContent:'center',padding:30},lockedTitle:{marginTop:15,fontSize:22,lineHeight:26,fontWeight:'700'},lockedBtn:{marginTop:18,height:48,borderRadius:24,paddingHorizontal:18,alignItems:'center',justifyContent:'center'},lockedBtnText:{fontSize:13,lineHeight:17,fontWeight:'600'}})
