import { useCallback, useEffect, useMemo, useState } from 'react';
import { ActivityIndicator, RefreshControl, ScrollView, StyleSheet, Text, TextInput, View, useColorScheme } from 'react-native';
import { CarCard } from '@/src/components/CarCard';
import { getCatalog } from '@/src/lib/api';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

export default function CatalogScreen() {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const [cars, setCars] = useState<CatalogCar[]>([]);
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const load = useCallback(async () => { try { setCars(await getCatalog()); } finally { setLoading(false); setRefreshing(false); } }, []);
  useEffect(() => { void load(); }, [load]);
  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    return cars.filter((car) => car.status !== 'hidden' && (!q || `${car.brand} ${car.model} ${car.trim ?? ''}`.toLowerCase().includes(q)));
  }, [cars, query]);

  return (
    <ScrollView style={{ backgroundColor: palette.background }} contentInsetAdjustmentBehavior="automatic" refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); void load(); }} />} contentContainerStyle={styles.content}>
      <Text style={[styles.title, { color: palette.text }]}>Автомобили</Text>
      <TextInput value={query} onChangeText={setQuery} placeholder="Марка или модель" placeholderTextColor={palette.secondary} style={[styles.search, { backgroundColor: palette.surface, color: palette.text, borderColor: palette.hairline }]} />
      {loading ? <ActivityIndicator style={{ marginTop: 30 }} /> : null}
      <View style={styles.grid}>{visible.map((car) => <CarCard key={car.id} car={car} />)}</View>
      <View style={{ height: 80 }} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({ content: { padding: 18, gap: 16 }, title: { fontSize: 34, fontWeight: '700', letterSpacing: -1 }, search: { borderRadius: 18, borderWidth: StyleSheet.hairlineWidth, paddingHorizontal: 16, height: 50, fontSize: 17 }, grid: { gap: 16 } });
