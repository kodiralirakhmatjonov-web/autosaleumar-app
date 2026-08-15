import { Pressable, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { SymbolView } from 'expo-symbols';
import { colors } from '@/src/theme/colors';
export function SectionHeading({kicker,title,text,action,onAction}:{kicker?:string;title:string;text?:string;action?:string;onAction?:()=>void}){
 const p=colors[useColorScheme()==='dark'?'dark':'light'];
 return <View style={s.wrap}><View style={s.top}><View style={s.copy}>{kicker?<Text style={[s.kicker,{color:p.secondary}]}>{kicker}</Text>:null}<Text style={[s.title,{color:p.text}]}>{title}</Text></View>{action&&onAction?<Pressable onPress={onAction} style={s.action}><Text style={[s.actionText,{color:p.blue}]}>{action}</Text><SymbolView name={{ios:'chevron.right',android:'chevron_right',web:'chevron_right'}} size={13} tintColor={p.blue}/></Pressable>:null}</View>{text?<Text style={[s.text,{color:p.secondary}]}>{text}</Text>:null}</View>
}
const s=StyleSheet.create({wrap:{paddingHorizontal:20},top:{flexDirection:'row',alignItems:'flex-end',justifyContent:'space-between',gap:12},copy:{flex:1},kicker:{fontSize:10,lineHeight:13,fontWeight:'700',letterSpacing:1.65,marginBottom:7},title:{fontSize:32,lineHeight:35,fontWeight:'700',letterSpacing:-1.05},text:{marginTop:10,fontSize:15,lineHeight:22,maxWidth:620},action:{flexDirection:'row',alignItems:'center',gap:4,paddingBottom:2},actionText:{fontSize:14,lineHeight:18,fontWeight:'600'}})
