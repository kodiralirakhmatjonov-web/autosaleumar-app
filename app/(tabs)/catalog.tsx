import { useLocalSearchParams } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
  useColorScheme,
} from 'react-native';
import { GlassView, isGlassEffectAPIAvailable } from 'expo-glass-effect';
import { CarCard } from '@/src/components/CarCard';
import { getCatalog } from '@/src/lib/api';
import type { CatalogCar, CarStatus } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

type FilterKey = 'all' | 'showroom' | 'stock' | 'transit';

const FILTERS: Array<{ key: FilterKey; label: string; statuses?: CarStatus[] }> = [
  { key: 'all', label: 'Все' },
  { key: 'showroom', label: 'В шоуруме', statuses: ['in_showroom'] },
  { key: 'stock', label: 'В наличии', statuses: ['in_stock'] },
  { key: 'transit', label: 'В пути', statuses: ['in_transit', 'made_to_order'] },
];

function FilterChip({ active, label, onPress }: { active: boolean; label: string; onPress: () => void }) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const nativeGlass = Platform.OS === 'ios' && isGlassEffectAPIAvailable();
  const inner = <Text style={[styles.filterLabel, { color: active ? '#FFFFFF' : palette.text }]}>{label}</Text>;

  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={({ pressed }) => pressed && styles.chipPressed}>
      {nativeGlass && !active ? (
        <GlassView isInteractive glassEffectStyle="regular" style={styles.filterChip}>{inner}</GlassView>
      ) : (
        <View
          style={[
            styles.filterChip,
            active ? styles.filterChipActive : styles.filterChipFallback,
            !active && { borderColor: palette.hairline },
          ]}
        >
          {inner}
        </View>
      )}
    </Pressable>
  );
}

export default function CatalogScreen() {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const params = useLocalSearchParams<{ q?: string }>();
  const [cars, setCars] = useState<CatalogCar[]>([]);
  const [query, setQuery] = useState(typeof params.q === 'string' ? params.q : '');
  const [filter, setFilter] = useState<FilterKey>('all');
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async () => {
    try {
      setCars(await getCatalog());
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);
  useEffect(() => { if (typeof params.q === 'string') setQuery(params.q); }, [params.q]);

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    const selected = FILTERS.find((item) => item.key === filter);
    return cars.filter((car) => {
      if (car.status === 'hidden') return false;
      if (selected?.statuses && !selected.statuses.includes(car.status)) return false;
      if (!q) return true;
      return `${car.brand} ${car.model} ${car.trim ?? ''}`.toLowerCase().includes(q);
    });
  }, [cars, filter, query]);

  return (
    <ScrollView
      style={{ backgroundColor: palette.background }}
      contentInsetAdjustmentBehavior="automatic"
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); void load(); }} />}
      contentContainerStyle={styles.content}
    >
      <View style={styles.shell}>
        <View style={styles.headerRow}>
          <View style={styles.headerCopy}>
            <Text style={[styles.largeTitle, { color: palette.text }]}>Автомобили</Text>
            <Text style={[styles.subtitle, { color: palette.secondary }]}>Коллекция Auto Sale Umar</Text>
          </View>
          <View style={[styles.countBadge, { backgroundColor: palette.fill }]}>
            <Text style={[styles.countBadgeText, { color: palette.secondary }]}>{cars.filter((car) => car.status !== 'hidden').length}</Text>
          </View>
        </View>

        <View style={[styles.search, styles.webGlass, { backgroundColor: palette.fill, borderColor: palette.hairline }]}> 
          <SymbolView name={{ ios: 'magnifyingglass', android: 'search', web: 'search' }} size={18} tintColor={palette.secondary} weight="medium" />
          <TextInput
            value={query}
            onChangeText={setQuery}
            placeholder="Поиск"
            placeholderTextColor={palette.secondary}
            style={[styles.searchInput, { color: palette.text }]}
            returnKeyType="search"
            clearButtonMode="while-editing"
          />
        </View>

        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filters}>
          {FILTERS.map((item) => (
            <FilterChip key={item.key} label={item.label} active={filter === item.key} onPress={() => setFilter(item.key)} />
          ))}
        </ScrollView>

        <View style={styles.resultRow}>
          <Text style={[styles.resultText, { color: palette.secondary }]}>
            {loading ? 'Обновляем каталог…' : `${visible.length} ${visible.length === 1 ? 'автомобиль' : 'автомобилей'}`}
          </Text>
        </View>

        {loading ? <ActivityIndicator style={styles.loader} /> : null}
        <View style={styles.grid}>{visible.map((car) => <CarCard key={car.id} car={car} />)}</View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { width: '100%', paddingHorizontal: 18, paddingTop: 12, paddingBottom: 118 },
  shell: { width: '100%', maxWidth: 680, alignSelf: 'center' },
  headerRow: { minHeight: 68, flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', gap: 16 },
  headerCopy: { flex: 1 },
  largeTitle: { fontSize: 34, lineHeight: 39, fontWeight: '700', letterSpacing: -1.15 },
  subtitle: { marginTop: 2, fontSize: 15, lineHeight: 20, letterSpacing: -0.15 },
  countBadge: { minWidth: 34, height: 34, borderRadius: 17, paddingHorizontal: 10, alignItems: 'center', justifyContent: 'center', marginTop: 2 },
  countBadgeText: { fontSize: 13, lineHeight: 17, fontWeight: '600' },
  search: { marginTop: 14, height: 50, borderRadius: 20, paddingHorizontal: 14, flexDirection: 'row', alignItems: 'center', gap: 10, borderWidth: StyleSheet.hairlineWidth },
  webGlass: { overflow: 'hidden' },
  searchInput: { flex: 1, height: '100%', fontSize: 17, letterSpacing: -0.22 },
  filters: { gap: 8, paddingTop: 12, paddingRight: 8 },
  filterChip: { minHeight: 36, borderRadius: 18, paddingHorizontal: 14, alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
  filterChipActive: { backgroundColor: '#111111' },
  filterChipFallback: { backgroundColor: 'rgba(255,255,255,0.76)', borderWidth: StyleSheet.hairlineWidth },
  filterLabel: { fontSize: 13, lineHeight: 17, fontWeight: '600', letterSpacing: -0.1 },
  chipPressed: { transform: [{ scale: 0.97 }], opacity: 0.9 },
  resultRow: { paddingTop: 17, paddingBottom: 13 },
  resultText: { fontSize: 13, lineHeight: 17, fontWeight: '500' },
  loader: { paddingVertical: 30 },
  grid: { gap: 28 },
});
