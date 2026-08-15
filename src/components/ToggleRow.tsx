import { StyleSheet, Switch, Text, View, useColorScheme } from 'react-native';
import { colors } from '@/src/theme/colors';

export function ToggleRow({ label, detail, value, onValueChange }: { label: string; detail?: string; value: boolean; onValueChange: (value: boolean) => void }) {
  const p = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  return <View style={[s.row,{backgroundColor:p.surface,borderColor:p.hairline}]}><View style={s.copy}><Text style={[s.label,{color:p.text}]}>{label}</Text>{detail?<Text style={[s.detail,{color:p.secondary}]}>{detail}</Text>:null}</View><Switch value={value} onValueChange={onValueChange}/></View>;
}
const s=StyleSheet.create({row:{minHeight:66,borderRadius:22,borderWidth:StyleSheet.hairlineWidth,paddingHorizontal:15,paddingVertical:10,flexDirection:'row',alignItems:'center',gap:12,marginTop:10},copy:{flex:1},label:{fontSize:14,lineHeight:18,fontWeight:'600'},detail:{marginTop:3,fontSize:11,lineHeight:15}});
