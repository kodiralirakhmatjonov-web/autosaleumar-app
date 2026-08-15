import * as ImagePicker from 'expo-image-picker';
import { Image } from 'expo-image';
import { useState } from 'react';
import { ActivityIndicator, Alert, Pressable, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { AdminShell } from '@/src/components/AdminShell';
import { ChoiceRail } from '@/src/components/ChoiceRail';
import { getBrandMedia, uploadBrandCover } from '@/src/lib/api';
import type { BrandMediaItem } from '@/src/lib/types';
import { useApp } from '@/src/state/AppProvider';
import { brandNames } from '@/src/site/assets';
import { colors } from '@/src/theme/colors';
export default function Brands(){const p=colors[useColorScheme()==='dark'?'dark':'light'];const {token}=useApp();const [brand,setBrand]=useState(brandNames[0]);const [images,setImages]=useState<BrandMediaItem[]>([]);const [busy,setBusy]=useState(false);const load=async(b=brand)=>{try{setImages(await getBrandMedia(b))}catch{setImages([])}};const pick=async()=>{if(!token)return;const r=await ImagePicker.launchImageLibraryAsync({mediaTypes:['images'],quality:1});if(r.canceled)return;setBusy(true);try{const a=r.assets[0];await uploadBrandCover(token,brand,{uri:a.uri,name:a.fileName,mimeType:a.mimeType});await load();Alert.alert('Готово','Обложка бренда загружена в R2.')}catch(e){Alert.alert('Ошибка',e instanceof Error?e.message:'Не удалось загрузить')}finally{setBusy(false)}};return <AdminShell title="Бренды" subtitle="Обложки марок для страниц автомобилей."><Text style={[s.label,{color:p.secondary}]}>МАРКА</Text><ChoiceRail value={brand} onChange={(b)=>{setBrand(b);void load(b)}} items={brandNames.map(value=>({value,label:value}))}/><Pressable disabled={busy} onPress={()=>void pick()} style={[s.button,{backgroundColor:p.text},busy&&{opacity:.6}]}>{busy?<ActivityIndicator color={p.background}/>:<Text style={[s.buttonText,{color:p.background}]}>Загрузить обложку</Text>}</Pressable><View style={s.grid}>{images.map(x=><Image key={x.key} source={{uri:x.url.startsWith('http')?x.url:`https://autosaleumar.com${x.url}`}} style={s.image} contentFit="cover"/>)}</View></AdminShell>}
const s=StyleSheet.create({label:{fontSize:10,lineHeight:13,fontWeight:'700',letterSpacing:.9,marginTop:26,marginBottom:8},button:{height:52,borderRadius:26,marginTop:20,alignItems:'center',justifyContent:'center'},buttonText:{fontSize:13,lineHeight:17,fontWeight:'600'},grid:{marginTop:18,gap:10},image:{height:230,borderRadius:28}})
