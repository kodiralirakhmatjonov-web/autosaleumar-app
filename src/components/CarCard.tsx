import { Image } from 'expo-image';
import { router } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { Pressable, Share, StyleSheet, Text, View, useColorScheme, type StyleProp, type ViewStyle } from 'react-native';
import { absoluteMediaUrl } from '@/src/lib/api';
import { firstPhoto, formatPrice } from '@/src/lib/format';
import type { CatalogCar, Language } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';
import { StatusPill } from './StatusPill';

export function CarCard({ car, language='ru', compact=false, style }: { car: CatalogCar; language?: Language; compact?: boolean; style?: StyleProp<ViewStyle> }) {
  const palette=colors[useColorScheme()==='dark'?'dark':'light'];
  const photo=absoluteMediaUrl(firstPhoto(car));
  const color=car.variants?.[0];
  const open=()=>router.push({pathname:'/car/[slug]',params:{slug:car.slug}});
  const share=async()=>{ try { await Share.share({message:`${car.brand} ${car.model} — ${formatPrice(car,language)}\nhttps://autosaleumar.com/car/?slug=${encodeURIComponent(car.slug)}`}); } catch {} };
  return <View style={[s.card,{backgroundColor:palette.surface,borderColor:palette.hairline},compact&&s.compact,style]}>
    <Pressable onPress={open} style={({pressed})=>[s.press,pressed&&s.pressed]}>
      <View style={[s.media,compact&&s.compactMedia,{backgroundColor:palette.fill}]}>
        {photo?<Image source={{uri:photo}} style={StyleSheet.absoluteFill} contentFit="cover" transition={180}/>:<View style={s.fallback}><SymbolView name={{ios:'car.fill',android:'directions_car',web:'directions_car'}} size={42} tintColor={palette.tertiary}/></View>}
        <View style={s.status}><StatusPill status={car.status} language={language}/></View>
        <Pressable onPress={(e)=>{e.stopPropagation();void share();}} style={s.share}><View style={[s.shareInner,{backgroundColor:'rgba(255,255,255,0.82)'}]}><SymbolView name={{ios:'square.and.arrow.up',android:'share',web:'share'}} size={16} tintColor="#111214" weight="medium"/></View></Pressable>
      </View>
      <View style={[s.body,compact&&s.compactBody]}>
        <View style={s.topline}><Text numberOfLines={1} style={[s.brand,{color:palette.secondary}]}>{car.brand.toUpperCase()}</Text>{car.year?<Text style={[s.year,{color:palette.secondary}]}>{car.year}</Text>:null}</View>
        <Text numberOfLines={1} style={[s.model,{color:palette.text},compact&&s.compactModel]}>{car.model}</Text>
        {car.trim?<Text numberOfLines={1} style={[s.trim,{color:palette.secondary}]}>{car.trim}</Text>:null}
        {car.engineText?<Text numberOfLines={1} style={[s.engine,{color:palette.secondary}]}>{car.engineText}</Text>:null}
        {color?<View style={s.colorRow}><View style={[s.swatch,{backgroundColor:color.exteriorSwatch||'#111214',borderColor:palette.hairline}]}/><Text numberOfLines={1} style={[s.colorText,{color:palette.secondary}]}>{color.exteriorColorName||'Цвет кузова'}</Text></View>:null}
        <View style={s.priceRow}><View><Text style={[s.priceLabel,{color:palette.secondary}]}>{language==='ru'?'Цена':'Narx'}</Text><Text numberOfLines={1} style={[s.price,{color:palette.text}]}>{formatPrice(car,language)}</Text></View><View style={[s.chevron,{backgroundColor:palette.fill}]}><SymbolView name={{ios:'chevron.right',android:'chevron_right',web:'chevron_right'}} size={15} tintColor={palette.text} weight="semibold"/></View></View>
      </View>
    </Pressable>
  </View>
}

const s=StyleSheet.create({
 card:{borderRadius:32,borderWidth:StyleSheet.hairlineWidth,overflow:'hidden'},compact:{width:300},press:{flex:1},pressed:{opacity:.88},media:{height:310,overflow:'hidden'},compactMedia:{height:220},fallback:{flex:1,alignItems:'center',justifyContent:'center'},status:{position:'absolute',left:14,top:14},share:{position:'absolute',right:14,top:14},shareInner:{width:38,height:38,borderRadius:19,alignItems:'center',justifyContent:'center'},body:{padding:18,paddingTop:16},compactBody:{padding:15},topline:{flexDirection:'row',alignItems:'center',justifyContent:'space-between',gap:10},brand:{flex:1,fontSize:10,lineHeight:13,fontWeight:'700',letterSpacing:1.4},year:{fontSize:13,lineHeight:17,fontWeight:'500'},model:{marginTop:5,fontSize:28,lineHeight:31,fontWeight:'700',letterSpacing:-.9},compactModel:{fontSize:23,lineHeight:27},trim:{marginTop:4,fontSize:14,lineHeight:18},engine:{marginTop:7,fontSize:12,lineHeight:16},colorRow:{marginTop:13,flexDirection:'row',alignItems:'center',gap:7},swatch:{width:13,height:13,borderRadius:7,borderWidth:StyleSheet.hairlineWidth},colorText:{fontSize:11,lineHeight:15,flex:1},priceRow:{marginTop:20,flexDirection:'row',alignItems:'flex-end',justifyContent:'space-between',gap:12},priceLabel:{fontSize:9,lineHeight:12,fontWeight:'600',letterSpacing:.7,textTransform:'uppercase'},price:{marginTop:3,fontSize:20,lineHeight:24,fontWeight:'700',letterSpacing:-.35},chevron:{width:38,height:38,borderRadius:19,alignItems:'center',justifyContent:'center'}
})
