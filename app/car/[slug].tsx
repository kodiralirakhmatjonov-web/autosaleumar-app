import { Image } from 'expo-image';
import { Stack, useLocalSearchParams } from 'expo-router';
import { useEffect, useMemo, useState } from 'react';
import { ActivityIndicator, Linking, ScrollView, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { AppleGlassButton } from '@/src/components/AppleGlassButton';
import { absoluteMediaUrl, getCar } from '@/src/lib/api';
import { formatPrice, statusLabel } from '@/src/lib/format';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

function SpecRow({ label, value, last = false }: { label: string; value: string; last?: boolean }) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  return (
    <View style={[styles.specRow, !last && { borderBottomColor: palette.hairline, borderBottomWidth: StyleSheet.hairlineWidth }]}> 
      <Text style={[styles.specLabel, { color: palette.secondary }]}>{label}</Text>
      <Text style={[styles.specValue, { color: palette.text }]}>{value}</Text>
    </View>
  );
}

export default function CarScreen() {
  const { slug } = useLocalSearchParams<{ slug: string }>();
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const [car, setCar] = useState<CatalogCar | null>(null);
  const [error, setError] = useState(false);

  useEffect(() => {
    if (!slug) return;
    getCar(slug).then(setCar).catch(() => setError(true));
  }, [slug]);

  const image = useMemo(() => {
    if (!car) return null;
    return absoluteMediaUrl(car.coverUrl ?? car.variants?.[0]?.photos?.[0]?.url);
  }, [car]);

  if (!car && !error) {
    return <View style={[styles.center, { backgroundColor: palette.background }]}><ActivityIndicator /></View>;
  }

  if (!car) {
    return <View style={[styles.center, { backgroundColor: palette.background }]}><Text style={{ color: palette.text }}>Автомобиль не найден.</Text></View>;
  }

  const specs = [
    car.year ? ['Год', String(car.year)] : null,
    car.engineText ? ['Двигатель', car.engineText] : null,
    car.horsepowerHp ? ['Мощность', `${car.horsepowerHp} л.с.`] : null,
    car.driveType ? ['Привод', car.driveType] : null,
    car.transmission ? ['Коробка', car.transmission] : null,
    car.mileageKm != null ? ['Пробег', `${new Intl.NumberFormat('ru-RU').format(car.mileageKm)} км`] : null,
  ].filter((item): item is [string, string] => Boolean(item));

  return (
    <>
      <Stack.Screen options={{ headerTitle: `${car.brand} ${car.model}` }} />
      <ScrollView
        style={{ backgroundColor: palette.background }}
        contentInsetAdjustmentBehavior="automatic"
        contentContainerStyle={styles.content}
      >
        <View style={styles.shell}>
          <View style={[styles.hero, { backgroundColor: palette.elevated, borderColor: palette.hairline }]}> 
            {image ? <Image source={image} contentFit="contain" transition={180} style={StyleSheet.absoluteFill} /> : null}
          </View>

          <View style={styles.copy}>
            <Text style={[styles.status, { color: palette.secondary }]}>{statusLabel(car.status).toUpperCase()}</Text>
            <Text style={[styles.title, { color: palette.text }]}>{car.brand} {car.model}</Text>
            {car.trim || car.year ? <Text style={[styles.trim, { color: palette.secondary }]}>{[car.trim, car.year].filter(Boolean).join(' · ')}</Text> : null}
            <Text style={[styles.price, { color: palette.text }]}>{formatPrice(car)}</Text>

            <View style={styles.actionRow}>
              <AppleGlassButton
                prominent
                label="Запросить автомобиль"
                symbol={{ ios: 'arrow.right', android: 'arrow_forward', web: 'arrow_forward' }}
                onPress={() => void Linking.openURL(`https://autosaleumar.com/request-car/?car=${encodeURIComponent(car.slug)}`)}
              />
            </View>

            {specs.length ? (
              <View style={[styles.specGroup, { backgroundColor: palette.surface, borderColor: palette.hairline }]}> 
                {specs.map(([label, value], index) => <SpecRow key={label} label={label} value={value} last={index === specs.length - 1} />)}
              </View>
            ) : null}

            <View style={styles.descriptionBlock}>
              <Text style={[styles.blockTitle, { color: palette.text }]}>Об автомобиле</Text>
              <Text style={[styles.description, { color: palette.secondary }]}>{car.descriptionRu || car.shortDescriptionRu || 'Подробная информация об автомобиле будет добавлена.'}</Text>
            </View>
          </View>
        </View>
      </ScrollView>
    </>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  content: { width: '100%', paddingHorizontal: 16, paddingBottom: 72 },
  shell: { width: '100%', maxWidth: 720, alignSelf: 'center' },
  hero: { width: '100%', aspectRatio: 1.38, borderRadius: 28, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden' },
  copy: { paddingTop: 22 },
  status: { fontSize: 11, fontWeight: '700', letterSpacing: 1.15 },
  title: { marginTop: 7, fontSize: 34, lineHeight: 38, fontWeight: '700', letterSpacing: -1.15 },
  trim: { marginTop: 5, fontSize: 16, lineHeight: 22 },
  price: { marginTop: 14, fontSize: 24, lineHeight: 29, fontWeight: '700', letterSpacing: -0.55 },
  actionRow: { marginTop: 20 },
  specGroup: { marginTop: 28, borderRadius: 24, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden' },
  specRow: { minHeight: 52, paddingHorizontal: 16, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 18 },
  specLabel: { flex: 1, fontSize: 15 },
  specValue: { flex: 1, fontSize: 15, fontWeight: '600', textAlign: 'right' },
  descriptionBlock: { paddingTop: 30 },
  blockTitle: { fontSize: 22, lineHeight: 26, fontWeight: '700', letterSpacing: -0.45 },
  description: { marginTop: 10, fontSize: 17, lineHeight: 25, letterSpacing: -0.1 },
});
