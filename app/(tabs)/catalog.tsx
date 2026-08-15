import { useLocalSearchParams } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
  useColorScheme,
} from 'react-native';
import { CarCard } from '@/src/components/CarCard';
import { getCatalog } from '@/src/lib/api';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

export default function CatalogScreen() {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const params = useLocalSearchParams<{ q?: string }>();
  const [cars, setCars] = useState<CatalogCar[]>([]);
  const [query, setQuery] = useState(typeof params.q === 'string' ? params.q : '');
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async () => {
    try { setCars(await getCatalog()); }
    finally { setLoading(false); setRefreshing(false); }
  }, []);

  useEffect(() => { void load(); }, [load]);
  useEffect(() => { if (typeof params.q === 'string') setQuery(params.q); }, [params.q]);

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    return cars.filter((car) => car.status !== 'hidden' && (!q || `${car.brand} ${car.model} ${car.trim ?? ''}`.toLowerCase().includes(q)));
  }, [cars, query]);

  return (
    <ScrollView
      style={{ backgroundColor: palette.background }}
      contentInsetAdjustmentBehavior="automatic"
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); void load(); }} />}
      contentContainerStyle={styles.content}
    >
      <View style={styles.shell}>
        <Text style={[styles.largeTitle, { color: palette.text }]}>Автомобили</Text>
        <Text style={[styles.subtitle, { color: palette.secondary }]}>Единый каталог Auto Sale Umar</Text>

        <View style={[styles.search, { backgroundColor: palette.fill }]}> 
          <SymbolView name={{ ios: 'magnifyingglass', android: 'search', web: 'search' }} size={18} tintColor={palette.secondary} />
          <TextInput
            value={query}
            onChangeText={setQuery}
            placeholder="Марка или модель"
            placeholderTextColor={palette.secondary}
            style={[styles.searchInput, { color: palette.text }]}
            returnKeyType="search"
            clearButtonMode="while-editing"
          />
        </View>

        <View style={styles.resultRow}>
          <Text style={[styles.resultText, { color: palette.secondary }]}>{loading ? 'Обновляем каталог…' : `${visible.length} автомобилей`}</Text>
        </View>

        {loading ? <ActivityIndicator style={styles.loader} /> : null}
        <View style={styles.grid}>{visible.map((car) => <CarCard key={car.id} car={car} />)}</View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { width: '100%', paddingHorizontal: 16, paddingTop: 22, paddingBottom: 112 },
  shell: { width: '100%', maxWidth: 720, alignSelf: 'center' },
  largeTitle: { fontSize: 34, lineHeight: 39, fontWeight: '700', letterSpacing: -1.2 },
  subtitle: { marginTop: 4, fontSize: 15, lineHeight: 21 },
  search: { marginTop: 22, height: 48, borderRadius: 16, paddingHorizontal: 13, flexDirection: 'row', alignItems: 'center', gap: 9 },
  searchInput: { flex: 1, height: '100%', fontSize: 17, letterSpacing: -0.2 },
  resultRow: { paddingTop: 15, paddingBottom: 12 },
  resultText: { fontSize: 13, fontWeight: '500' },
  loader: { paddingVertical: 30 },
  grid: { gap: 14 },
});
