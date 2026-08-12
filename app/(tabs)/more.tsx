import { Linking, Pressable, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { GlassPill } from '@/src/components/GlassPill';
import { colors } from '@/src/theme/colors';

export default function MoreScreen() {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  return (
    <View style={[styles.root, { backgroundColor: palette.background }]}>
      <Text style={[styles.title, { color: palette.text }]}>AutoSale Umar</Text>
      <Text style={[styles.text, { color: palette.secondary }]}>Премиальный автомобильный шоурум. Эта страница станет центром языка, контактов, визитов и настроек приложения.</Text>
      <Pressable onPress={() => void Linking.openURL('https://autosaleumar.com')}>
        <GlassPill><Text style={[styles.buttonText, { color: palette.text }]}>Открыть autosaleumar.com</Text></GlassPill>
      </Pressable>
    </View>
  );
}
const styles = StyleSheet.create({ root: { flex: 1, padding: 22, paddingTop: 72, gap: 18 }, title: { fontSize: 34, fontWeight: '700' }, text: { fontSize: 17, lineHeight: 24 }, buttonText: { fontSize: 16, fontWeight: '600' } });
