import { StyleSheet, Text, View, useColorScheme } from 'react-native';
import { colors } from '@/src/theme/colors';

export default function SavedScreen() {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  return <View style={[styles.root, { backgroundColor: palette.background }]}><Text style={[styles.title, { color: palette.text }]}>Избранное</Text><Text style={[styles.text, { color: palette.secondary }]}>На следующем этапе подключим постоянное избранное без обязательной регистрации.</Text></View>;
}
const styles = StyleSheet.create({ root: { flex: 1, padding: 22, paddingTop: 72 }, title: { fontSize: 34, fontWeight: '700' }, text: { marginTop: 12, fontSize: 17, lineHeight: 24 } });
