import { useCallback, useEffect, useState } from 'react';
import { ActivityIndicator, RefreshControl, ScrollView, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { Image } from 'expo-image';
import { CarCard } from '@/src/components/CarCard';
import { getCatalog } from '@/src/lib/api';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

export default function HomeScreen() {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const [cars, setCars] = useState<CatalogCar[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    try { setError(null); setCars(await getCatalog(30)); }
    catch { setError('Не удалось загрузить автомобили. Проверьте интернет или API.'); }
    finally { setLoading(false); setRefreshing(false); }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const featured = cars.filter((car) => !['sold', 'hidden'].includes(car.status)).slice(0, 4);

  return (
    <ScrollView
      style={{ backgroundColor: palette.background }}
      contentInsetAdjustmentBehavior="automatic"
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); void load(); }} />}
      contentContainerStyle={styles.content}
    >
      <View style={styles.wordmarkWrap}>
        <Image source={require('@/assets/wordmark-black.png')} contentFit="contain" style={styles.wordmark} />
      </View>
      <Text style={[styles.eyebrow, { color: palette.secondary }]}>PREMIUM AUTOMOTIVE SHOWROOM</Text>
      <Text style={[styles.title, { color: palette.text }]}>Ваш следующий автомобиль начинается здесь.</Text>
      <Text style={[styles.subtitle, { color: palette.secondary }]}>Единый каталог AutoSale Umar. Автомобили в шоуруме, в наличии и в пути — напрямую из общей системы.</Text>

      {loading ? <ActivityIndicator style={styles.loader} /> : null}
      {error ? <Text style={[styles.error, { color: palette.secondary }]}>{error}</Text> : null}
      <View style={styles.list}>{featured.map((car, index) => <CarCard key={car.id} car={car} hero={index === 0} />)}</View>
      <View style={styles.footerSpace} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 18, paddingTop: 18, gap: 14 },
  wordmarkWrap: { height: 36, alignItems: 'flex-start', justifyContent: 'center', marginTop: 8 },
  wordmark: { width: 180, height: 34 },
  eyebrow: { fontSize: 12, fontWeight: '700', letterSpacing: 1.4, marginTop: 18 },
  title: { fontSize: 38, lineHeight: 42, fontWeight: '700', letterSpacing: -1.4, maxWidth: 350 },
  subtitle: { fontSize: 17, lineHeight: 24, maxWidth: 360, marginBottom: 12 },
  loader: { paddingVertical: 30 },
  error: { fontSize: 15, lineHeight: 21, paddingVertical: 20 },
  list: { gap: 18 },
  footerSpace: { height: 80 },
});
