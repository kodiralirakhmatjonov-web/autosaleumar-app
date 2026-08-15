import { router } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { Pressable, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { AdaptiveGlass } from '@/src/components/AdaptiveGlass';
import { colors } from '@/src/theme/colors';

export default function SavedScreen() {
  const dark = useColorScheme() === 'dark';
  const palette = colors[dark ? 'dark' : 'light'];

  return (
    <View style={[styles.root, { backgroundColor: palette.background }]}> 
      <View style={styles.shell}>
        <Text style={[styles.kicker, { color: palette.secondary }]}>YOUR COLLECTION</Text>
        <Text style={[styles.title, { color: palette.text }]}>Избранное</Text>
        <Text style={[styles.subtitle, { color: palette.secondary }]}>Автомобили, к которым хочется вернуться.</Text>

        <View style={[styles.hero, { backgroundColor: palette.surface, borderColor: palette.hairline }]}> 
          <AdaptiveGlass style={styles.heartGlass}>
            <SymbolView name={{ ios: 'heart.fill', android: 'favorite', web: 'favorite' }} size={26} tintColor={palette.text} />
          </AdaptiveGlass>
          <Text style={[styles.emptyTitle, { color: palette.text }]}>Соберите свою коллекцию</Text>
          <Text style={[styles.text, { color: palette.secondary }]}>Добавляйте автомобили в избранное и сравнивайте их без лишних списков и сообщений.</Text>
          <Pressable onPress={() => router.push('/catalog')} style={({ pressed }) => [styles.catalogButton, pressed && styles.pressed]}>
            <Text style={styles.catalogButtonText}>Открыть каталог</Text>
            <SymbolView name={{ ios: 'arrow.right', android: 'arrow_forward', web: 'arrow_forward' }} size={16} tintColor="#FFFFFF" weight="semibold" />
          </Pressable>
        </View>

        <View style={styles.tipRow}>
          <View style={[styles.tipIcon, { backgroundColor: palette.fill }]}>
            <SymbolView name={{ ios: 'hand.tap.fill', android: 'touch_app', web: 'touch_app' }} size={18} tintColor={palette.text} />
          </View>
          <View style={styles.tipCopy}>
            <Text style={[styles.tipTitle, { color: palette.text }]}>Быстрый доступ</Text>
            <Text style={[styles.tipText, { color: palette.secondary }]}>Сердце на странице автомобиля добавит его сюда. Хранение без регистрации подключим следующим этапом.</Text>
          </View>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, paddingHorizontal: 16, paddingTop: 38 },
  shell: { width: '100%', maxWidth: 720, alignSelf: 'center' },
  pressed: { opacity: 0.82, transform: [{ scale: 0.992 }] },
  kicker: { fontSize: 9, lineHeight: 12, fontWeight: '700', letterSpacing: 1.55 },
  title: { marginTop: 7, fontSize: 40, lineHeight: 43, fontWeight: '700', letterSpacing: -1.6 },
  subtitle: { marginTop: 8, fontSize: 15, lineHeight: 21 },
  hero: { marginTop: 28, minHeight: 350, borderRadius: 34, borderWidth: StyleSheet.hairlineWidth, padding: 24, justifyContent: 'flex-end' },
  heartGlass: { position: 'absolute', top: 22, left: 22, width: 58, height: 58, borderRadius: 29, alignItems: 'center', justifyContent: 'center' },
  emptyTitle: { maxWidth: 440, fontSize: 29, lineHeight: 33, fontWeight: '700', letterSpacing: -0.9 },
  text: { marginTop: 10, maxWidth: 500, fontSize: 15, lineHeight: 22 },
  catalogButton: { marginTop: 22, alignSelf: 'flex-start', minHeight: 50, borderRadius: 25, backgroundColor: '#111113', paddingHorizontal: 18, flexDirection: 'row', alignItems: 'center', gap: 9 },
  catalogButtonText: { color: '#FFFFFF', fontSize: 14, lineHeight: 18, fontWeight: '600' },
  tipRow: { paddingTop: 30, flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  tipIcon: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
  tipCopy: { flex: 1, paddingTop: 2 },
  tipTitle: { fontSize: 15, lineHeight: 19, fontWeight: '600' },
  tipText: { marginTop: 4, fontSize: 13, lineHeight: 19 },
});
