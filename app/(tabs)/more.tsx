import type { ComponentProps } from 'react';
import { Image } from 'expo-image';
import { SymbolView } from 'expo-symbols';
import { Linking, Pressable, ScrollView, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { AdaptiveGlass } from '@/src/components/AdaptiveGlass';
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
      <AdaptiveGlass style={styles.rowIcon}>
        <SymbolView name={symbol} size={18} tintColor={palette.text} weight="semibold" />
      </AdaptiveGlass>
      <View style={styles.rowCopy}>
        <Text style={[styles.rowTitle, { color: palette.text }]}>{title}</Text>
        {subtitle ? <Text style={[styles.rowSubtitle, { color: palette.secondary }]}>{subtitle}</Text> : null}
      </View>
      <SymbolView name={{ ios: 'chevron.right', android: 'chevron_right', web: 'chevron_right' }} size={15} tintColor={palette.tertiary} weight="semibold" />
    </Pressable>
  );
}

export default function MoreScreen() {
  const dark = useColorScheme() === 'dark';
  const palette = colors[dark ? 'dark' : 'light'];

  return (
    <ScrollView style={{ backgroundColor: palette.background }} contentInsetAdjustmentBehavior="automatic" contentContainerStyle={styles.content}>
      <View style={styles.shell}>
        <Text style={[styles.kicker, { color: palette.secondary }]}>AUTO SALE UMAR</Text>
        <Text style={[styles.title, { color: palette.text }]}>Ещё</Text>

        <View style={[styles.brandCard, { backgroundColor: palette.surface, borderColor: palette.hairline }]}>
          <Image source={dark ? require('@/assets/wordmark-white.png') : require('@/assets/wordmark-black.png')} contentFit="contain" style={styles.wordmark} />
          <View style={styles.brandMeta}>
            <View style={styles.brandStatus}>
              <View style={styles.liveDot} />
              <Text style={[styles.brandStatusText, { color: palette.secondary }]}>Шоурум · Ташкент</Text>
            </View>
            <Text style={[styles.brandText, { color: palette.secondary }]}>Единая цифровая экосистема автомобилей.</Text>
          </View>
        </View>

        <Text style={[styles.groupLabel, { color: palette.secondary }]}>СЕРВИСЫ</Text>
        <View style={[styles.group, { backgroundColor: palette.surface, borderColor: palette.hairline }]}> 
          <Row
            title="Персональный подбор"
            subtitle="Запросить автомобиль под ваши параметры"
            symbol={{ ios: 'sparkles', android: 'auto_awesome', web: 'auto_awesome' }}
            onPress={() => void Linking.openURL('https://autosaleumar.com/request-car/')}
          />
          <View style={[styles.separator, { backgroundColor: palette.hairline }]} />
          <Row
            title="Шоурум"
            subtitle="Открыть локацию в Яндекс Картах"
            symbol={{ ios: 'location.fill', android: 'location_on', web: 'location_on' }}
            onPress={() => void Linking.openURL('https://yandex.ru/maps/org/auto_sale_umar/98317002086')}
          />
          <View style={[styles.separator, { backgroundColor: palette.hairline }]} />
          <Row
            title="Сайт Auto Sale Umar"
            subtitle="autosaleumar.com"
            symbol={{ ios: 'safari.fill', android: 'public', web: 'public' }}
            onPress={() => void Linking.openURL('https://autosaleumar.com')}
          />
        </View>

        <View style={styles.systemRow}>
          <SymbolView name={{ ios: 'checkmark.seal.fill', android: 'verified', web: 'verified' }} size={17} tintColor={palette.secondary} />
          <Text style={[styles.systemText, { color: palette.secondary }]}>Каталог приложения синхронизирован с основной системой Auto Sale Umar.</Text>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { width: '100%', paddingHorizontal: 16, paddingTop: 30, paddingBottom: 128 },
  shell: { width: '100%', maxWidth: 720, alignSelf: 'center' },
  pressed: { opacity: 0.64 },
  kicker: { fontSize: 9, lineHeight: 12, fontWeight: '700', letterSpacing: 1.55 },
  title: { marginTop: 7, fontSize: 40, lineHeight: 43, fontWeight: '700', letterSpacing: -1.6 },
  brandCard: { marginTop: 26, minHeight: 178, borderRadius: 32, borderWidth: StyleSheet.hairlineWidth, padding: 20, justifyContent: 'space-between' },
  wordmark: { width: 168, height: 34 },
  brandMeta: { paddingTop: 30 },
  brandStatus: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  liveDot: { width: 7, height: 7, borderRadius: 4, backgroundColor: '#30D158' },
  brandStatusText: { fontSize: 12, lineHeight: 16, fontWeight: '600' },
  brandText: { marginTop: 6, maxWidth: 440, fontSize: 13, lineHeight: 19 },
  groupLabel: { marginTop: 34, marginBottom: 10, marginLeft: 4, fontSize: 9, lineHeight: 12, fontWeight: '700', letterSpacing: 1.35 },
  group: { borderRadius: 28, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden' },
  row: { minHeight: 76, paddingHorizontal: 14, flexDirection: 'row', alignItems: 'center', gap: 12 },
  rowIcon: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
  rowCopy: { flex: 1, paddingVertical: 12 },
  rowTitle: { fontSize: 15, fontWeight: '600', letterSpacing: -0.18 },
  rowSubtitle: { marginTop: 3, fontSize: 12, lineHeight: 17 },
  separator: { height: StyleSheet.hairlineWidth, marginLeft: 66 },
  systemRow: { paddingTop: 24, paddingHorizontal: 4, flexDirection: 'row', alignItems: 'flex-start', gap: 9 },
  systemText: { flex: 1, fontSize: 12, lineHeight: 17 },
});
