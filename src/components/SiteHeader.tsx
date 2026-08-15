import { Image } from 'expo-image';
import { router } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { Pressable, StyleSheet, View, useColorScheme } from 'react-native';
import { siteAssets } from '@/src/site/assets';
import { SiteGlass } from './SiteGlass';
import { colors } from '@/src/theme/colors';

export function SiteHeader({ back = false, profile = true }: { back?: boolean; profile?: boolean }) {
  const dark = useColorScheme() === 'dark';
  const palette=colors[dark?'dark':'light'];
  return (
    <View style={styles.wrap}>
      {back ? <Pressable onPress={() => router.back()} hitSlop={10}><SiteGlass interactive style={styles.round}><SymbolView name={{ios:'chevron.left',android:'arrow_back',web:'arrow_back'}} size={19} tintColor={palette.text} weight="semibold" /></SiteGlass></Pressable> : <View style={styles.roundSpacer} />}
      <Image source={dark?siteAssets.wordmarkWhite:siteAssets.wordmarkBlack} contentFit="contain" style={styles.logo} />
      {profile ? <Pressable onPress={() => router.push('/(tabs)/profile')} hitSlop={10}><SiteGlass interactive style={styles.round}><SymbolView name={{ios:'person.crop.circle',android:'account_circle',web:'account_circle'}} size={21} tintColor={palette.text} weight="medium" /></SiteGlass></Pressable> : <View style={styles.roundSpacer}/>} 
    </View>
  );
}
const styles=StyleSheet.create({ wrap:{ height:58,flexDirection:'row',alignItems:'center',justifyContent:'space-between' }, logo:{ width:154,height:34 }, round:{ width:42,height:42,borderRadius:21,alignItems:'center',justifyContent:'center' },roundSpacer:{width:42,height:42} });
