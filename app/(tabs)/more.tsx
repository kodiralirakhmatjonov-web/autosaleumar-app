import type { ComponentProps } from 'react';
import { SymbolView } from 'expo-symbols';
import { Linking, Pressable, ScrollView, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { colors } from '@/src/theme/colors';

type RowProps = {
  title: string;
  subtitle?: string;
  symbol: ComponentProps<typeof SymbolView>['name'];
  onPress: () => void;
};

function Row({ title, subtitle, symbol, onPress }: RowProps) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.row, pressed && styles.pressed]}>
      <View style={[styles.rowIcon, { backgroundColor: palette.fill }]}> 
        <SymbolView name={symbol} size={20} tintColor={palette.text} />
      </View>
      <View style={styles.rowCopy}>
        <Text style={[styles.rowTitle, { color: palette.text }]}>{title}</Text>
        {subtitle ? <Text style={[styles.rowSubtitle, { color: palette.secondary }]}>{subtitle}</Text> : null}
      </View>
      <SymbolView name={{ ios: 'chevron.right', android: 'chevron_right', web: 'chevron_right' }} size={16} tintColor={palette.tertiary} />
    </Pressable>
  );
}

export default function MoreScreen() {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  return (
    <ScrollView style={{ backgroundColor: palette.background }} contentInsetAdjustmentBehavior="automatic" contentContainerStyle={styles.content}>
      <View style={styles.shell}>
        <Text style={[styles.title, { color: palette.text }]}>Ещё</Text>
        <Text style={[styles.subtitle, { color: palette.secondary }]}>Auto Sale Umar</Text>

        <View style={[styles.group, { backgroundColor: palette.surface, borderColor: palette.hairline }]}> 
          <Row
            title="Открыть сайт"
            subtitle="autosaleumar.com"
            symbol={{ ios: 'globe', android: 'public', web: 'public' }}
            onPress={() => void Linking.openURL('https://autosaleumar.com')}
          />
          <View style={[styles.separator, { backgroundColor: palette.hairline }]} />
          <Row
            title="Персональный подбор"
            subtitle="Оставить запрос на автомобиль"
            symbol={{ ios: 'magnifyingglass', android: 'search', web: 'search' }}
            onPress={() => void Linking.openURL('https://autosaleumar.com/request-car/')}
          />
        </View>

        <View style={[styles.about, { backgroundColor: palette.surface, borderColor: palette.hairline }]}> 
          <SymbolView name={{ ios: 'info.circle', android: 'info', web: 'info' }} size={22} tintColor={palette.secondary} />
          <Text style={[styles.aboutText, { color: palette.secondary }]}>Премиальный автомобильный шоурум · Ташкент. Мобильное приложение использует ту же базу автомобилей, что и основной сайт.</Text>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { width: '100%', paddingHorizontal: 16, paddingTop: 22, paddingBottom: 112 },
  shell: { width: '100%', maxWidth: 720, alignSelf: 'center' },
  title: { fontSize: 34, lineHeight: 39, fontWeight: '700', letterSpacing: -1.2 },
  subtitle: { marginTop: 4, fontSize: 15 },
  group: { marginTop: 22, borderRadius: 24, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden' },
  row: { minHeight: 70, paddingHorizontal: 14, flexDirection: 'row', alignItems: 'center', gap: 12 },
  pressed: { opacity: 0.55 },
  rowIcon: { width: 38, height: 38, borderRadius: 12, alignItems: 'center', justifyContent: 'center' },
  rowCopy: { flex: 1, paddingVertical: 12 },
  rowTitle: { fontSize: 16, fontWeight: '600', letterSpacing: -0.2 },
  rowSubtitle: { marginTop: 2, fontSize: 13, lineHeight: 18 },
  separator: { height: StyleSheet.hairlineWidth, marginLeft: 64 },
  about: { marginTop: 16, borderRadius: 24, borderWidth: StyleSheet.hairlineWidth, padding: 18, flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  aboutText: { flex: 1, fontSize: 14, lineHeight: 20 },
});
