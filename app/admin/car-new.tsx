import { router } from 'expo-router';
import { useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, useColorScheme } from 'react-native';
import { AdminShell } from '@/src/components/AdminShell';
import { ChoiceRail } from '@/src/components/ChoiceRail';
import { FormField } from '@/src/components/FormField';
import { ToggleRow } from '@/src/components/ToggleRow';
import { createAdminCar } from '@/src/lib/api';
import type { CarDraft, CarStatus } from '@/src/lib/types';
import { brandNames } from '@/src/site/assets';
import { useApp } from '@/src/state/AppProvider';
import { colors } from '@/src/theme/colors';

export const emptyCarDraft: CarDraft = {
  brand: brandNames[0], model: '', year: '2026', trim: '', status: 'in_stock', countryCode: 'AE', arrivalDate: '',
  price: '', currency: 'USD', priceOnRequest: false, isPublic: false, isFeatured: false, mileageKm: '0', engineText: '', engineDisplacementL: '',
  fuelType: 'petrol', driveType: 'awd', transmission: 'automatic', seats: '5', horsepowerHp: '', torqueNm: '', acceleration0100: '',
  topSpeedKmh: '', fuelConsumptionL100: '', electricRangeKm: '', instagramUrl: '', shortDescriptionRu: '', shortDescriptionUz: '',
  descriptionRu: '', descriptionUz: '', exteriorColorName: '', exteriorSwatch: '#111214', interiorColorName: '', interiorSwatch: '#111214',
  vin: '', stockNumber: '', quantity: '1', variantId: null,
};

export const statusOptions: Array<{value:CarStatus;label:string}> = [
  {value:'in_stock',label:'В наличии'},{value:'in_showroom',label:'В шоуруме'},{value:'in_transit',label:'В пути'},
  {value:'made_to_order',label:'Под заказ'},{value:'reserved',label:'Резерв'},{value:'sold',label:'Продан'},{value:'hidden',label:'Скрыт'},
];

export function CarFormFields({ draft: d, onChange }: { draft: CarDraft; onChange: <K extends keyof CarDraft>(key: K, value: CarDraft[K]) => void }) {
  const p=colors[useColorScheme()==='dark'?'dark':'light'];
  const set=<K extends keyof CarDraft>(k:K)=>(v:CarDraft[K])=>onChange(k,v);
  return <>
    <Text style={[s.group,{color:p.secondary}]}>ОСНОВНОЕ</Text>
    <ChoiceRail value={d.brand} onChange={(v)=>onChange('brand',v)} items={brandNames.map(value=>({value,label:value}))}/>
    <FormField label="Модель" value={d.model} onChangeText={set('model')}/><FormField label="Год" value={d.year} onChangeText={set('year')} keyboardType="number-pad"/><FormField label="Комплектация" value={d.trim} onChangeText={set('trim')}/>
    <Text style={[s.label,{color:p.secondary}]}>СТАТУС</Text><ChoiceRail value={d.status} onChange={(v)=>onChange('status',v)} items={statusOptions}/>
    <FormField label="Страна / код" value={d.countryCode} onChangeText={set('countryCode')}/>{['in_transit','made_to_order','reserved'].includes(d.status)?<FormField label="Дата прибытия YYYY-MM-DD" value={d.arrivalDate} onChangeText={set('arrivalDate')}/>:null}

    <Text style={[s.group,{color:p.secondary}]}>ЦЕНА И ПУБЛИКАЦИЯ</Text>
    <FormField label="Цена" value={d.price} onChangeText={set('price')} keyboardType="numeric"/><Text style={[s.label,{color:p.secondary}]}>ВАЛЮТА</Text><ChoiceRail value={d.currency} onChange={(v)=>onChange('currency',v)} items={[{value:'USD',label:'USD'},{value:'EUR',label:'EUR'},{value:'UZS',label:'UZS'}]}/>
    <ToggleRow label="Цена по запросу" value={d.priceOnRequest} onValueChange={(v)=>onChange('priceOnRequest',v)}/><ToggleRow label="Опубликован" detail="Публичная карточка появится в каталоге после добавления фото кузова." value={d.isPublic} onValueChange={(v)=>onChange('isPublic',v)}/><ToggleRow label="Рекомендуемый" value={d.isFeatured} onValueChange={(v)=>onChange('isFeatured',v)}/>

    <Text style={[s.group,{color:p.secondary}]}>ТЕХНИЧЕСКИЕ ДАННЫЕ</Text>
    <FormField label="Пробег км" value={d.mileageKm} onChangeText={set('mileageKm')} keyboardType="numeric"/><FormField label="Двигатель" value={d.engineText} onChangeText={set('engineText')}/><FormField label="Объём двигателя, л" value={d.engineDisplacementL} onChangeText={set('engineDisplacementL')} keyboardType="decimal-pad"/><FormField label="Топливо" value={d.fuelType} onChangeText={set('fuelType')}/><FormField label="Привод" value={d.driveType} onChangeText={set('driveType')}/><FormField label="Коробка" value={d.transmission} onChangeText={set('transmission')}/><FormField label="Мест" value={d.seats} onChangeText={set('seats')} keyboardType="number-pad"/><FormField label="Мощность л.с." value={d.horsepowerHp} onChangeText={set('horsepowerHp')} keyboardType="numeric"/><FormField label="Крутящий момент Нм" value={d.torqueNm} onChangeText={set('torqueNm')} keyboardType="numeric"/><FormField label="0–100 сек" value={d.acceleration0100} onChangeText={set('acceleration0100')} keyboardType="decimal-pad"/><FormField label="Макс. скорость км/ч" value={d.topSpeedKmh} onChangeText={set('topSpeedKmh')} keyboardType="numeric"/><FormField label="Расход л/100 км" value={d.fuelConsumptionL100} onChangeText={set('fuelConsumptionL100')} keyboardType="decimal-pad"/><FormField label="Запас хода EV, км" value={d.electricRangeKm} onChangeText={set('electricRangeKm')} keyboardType="numeric"/>

    <Text style={[s.group,{color:p.secondary}]}>КОНТЕНТ</Text>
    <FormField label="Instagram обзор" value={d.instagramUrl} onChangeText={set('instagramUrl')}/><FormField label="Короткое описание RU" value={d.shortDescriptionRu} onChangeText={set('shortDescriptionRu')} multiline/><FormField label="Короткое описание UZ" value={d.shortDescriptionUz} onChangeText={set('shortDescriptionUz')} multiline/><FormField label="Описание RU" value={d.descriptionRu} onChangeText={set('descriptionRu')} multiline/><FormField label="Описание UZ" value={d.descriptionUz} onChangeText={set('descriptionUz')} multiline/>

    <Text style={[s.group,{color:p.secondary}]}>ЦВЕТОВОЙ ВАРИАНТ И УЧЁТ</Text>
    <FormField label="Цвет кузова" value={d.exteriorColorName} onChangeText={set('exteriorColorName')}/><FormField label="HEX кузова" value={d.exteriorSwatch} onChangeText={set('exteriorSwatch')}/><FormField label="Цвет салона" value={d.interiorColorName} onChangeText={set('interiorColorName')}/><FormField label="HEX салона" value={d.interiorSwatch} onChangeText={set('interiorSwatch')}/><FormField label="VIN" value={d.vin} onChangeText={set('vin')}/><FormField label="Внутренний номер" value={d.stockNumber} onChangeText={set('stockNumber')}/><FormField label="Количество" value={d.quantity} onChangeText={set('quantity')} keyboardType="number-pad"/>
  </>;
}

export default function NewCar(){const p=colors[useColorScheme()==='dark'?'dark':'light'];const {token}=useApp();const [d,setD]=useState<CarDraft>(emptyCarDraft);const [busy,setBusy]=useState(false);const submit=async()=>{if(!token)return;setBusy(true);try{const car=await createAdminCar(token,d);Alert.alert('Автомобиль создан',`${car.brand} ${car.model} сохранён в той же D1 базе.`,[{text:'Фото',onPress:()=>router.replace({pathname:'/admin/car-media',params:{id:String(car.id)}})},{text:'Готово',onPress:()=>router.back()}])}catch(e){Alert.alert('Не удалось создать',e instanceof Error?e.message:'Ошибка')}finally{setBusy(false)}};return <AdminShell title="Новый автомобиль" subtitle="Нативная версия той же формы Control System."><CarFormFields draft={d} onChange={(k,v)=>setD(x=>({...x,[k]:v}))}/><Pressable disabled={busy} onPress={()=>void submit()} style={[s.button,{backgroundColor:p.text},busy&&{opacity:.6}]}><Text style={[s.buttonText,{color:p.background}]}>{busy?'Сохраняем…':'Создать автомобиль'}</Text></Pressable></AdminShell>}
const s=StyleSheet.create({label:{fontSize:10,lineHeight:13,fontWeight:'700',letterSpacing:.9,marginTop:18,marginBottom:8},group:{marginTop:34,marginBottom:12,fontSize:10,lineHeight:13,fontWeight:'700',letterSpacing:1.5},button:{height:56,borderRadius:28,marginTop:30,alignItems:'center',justifyContent:'center'},buttonText:{fontSize:14,lineHeight:18,fontWeight:'600'}});
