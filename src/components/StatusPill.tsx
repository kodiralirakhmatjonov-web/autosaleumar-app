import { Text, View, StyleSheet } from 'react-native';
import { SiteGlass } from './SiteGlass';
import { statusLabel } from '@/src/lib/format';
import type { CarStatus, Language } from '@/src/lib/types';

export function StatusPill({ status, language = 'ru', glass = true }: { status: CarStatus; language?: Language; glass?: boolean }) {
  const dot = status === 'in_transit' ? '#FF9F0A' : status === 'reserved' ? '#0A84FF' : status === 'sold' ? '#8E8E93' : '#34C759';
  const content = <View style={styles.inner}><View style={[styles.dot,{backgroundColor:dot}]} /><Text style={styles.text}>{statusLabel(status, language)}</Text></View>;
  return glass ? <SiteGlass style={styles.glass}>{content}</SiteGlass> : <View style={styles.solid}>{content}</View>;
}
const styles=StyleSheet.create({
  glass:{ minHeight:34,borderRadius:17,paddingHorizontal:12,justifyContent:'center' },
  solid:{ minHeight:34,borderRadius:17,paddingHorizontal:12,justifyContent:'center',backgroundColor:'#F2F2F3' },
  inner:{ flexDirection:'row',alignItems:'center',gap:7 }, dot:{ width:7,height:7,borderRadius:4 },
  text:{ fontSize:12,lineHeight:15,fontWeight:'600',color:'#111214' },
});
