import { SymbolView } from 'expo-symbols';
import { useMemo, useState, useEffect } from 'react';
import {
  ActivityIndicator,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
  useColorScheme,
} from 'react-native';
import { AdaptiveGlass } from '@/src/components/AdaptiveGlass';
import { CarCard } from '@/src/components/CarCard';
import { getCatalog } from '@/src/lib/api';
import type { CatalogCar, CarStatus } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

type StatusFilter = 'all' | 'showroom' | 'stock' | 'transit';

const statusFilters: Array<{ key: StatusFilter; label: string; statuses?: CarStatus[] }> = [
  { key: 'all', label: 'Все' },
  { key: 'showroom', label: 'В шоуруме', statuses: ['in_showroom'] },
  { key: 'stock', label: 'В наличии', statuses: ['in_stock', 'in_showroom'] },
  { key: 'transit', label: 'В пути', statuses: ['in_transit', 'made_to_order'] },
];

export default function CatalogScreen() {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const [cars, setCars] = useState<CatalogCar[]>([]);
  const [query, setQuery] = useState('');
  const [status, setStatus] = useState<StatusFilter>('all');
  const [brand, setBrand] = useState('Все');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getCatalog(100).then(setCars).finally(() => setLoading(false));
  }, []);

  const brands = useMemo(() => ['Все', ...Array.from(new Set(cars.map((car) => car.brand))).sort((a, b) => a.localeCompare(b))], [cars]);

  const filtered = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    const selectedStatuses = statusFilters.find((item) => item.key === status)?.statuses;

    return cars.filter((car) => {
      if (['hidden', 'sold'].includes(car.status)) return false;
      if (selectedStatuses && !selectedStatuses.includes(car.status)) return false;
      if (brand !== 'Все' && car.brand !== brand) return false;
      if (!normalized) return true;
      return `${car.brand} ${car.model} ${car.trim ?? ''} ${car.year ?? ''}`.toLowerCase().includes(normalized);
    });
  }, [brand, cars, query, status]);

  return (
    <ScrollView
      style={{ backgroundColor: palette.background }}
      contentInsetAdjustmentBehavior="automatic"
      keyboardShouldPersistTaps="handled"
      contentContainerStyle={styles.content}
    >
      <View style={styles.shell}>
        <View style={styles.headerRow}>
          <View style={styles.headerCopy}>
            <Text style={[styles.kicker, { color: palette.secondary }]}>AUTO SALE UMAR</Text>
            <Text style={[styles.title, { color: palette.text }]}>Автомобили</Text>
            <Text style={[styles.subtitle, { color: palette.secondary }]}>Каталог, статусы и комплектации в одной ленте.</Text>
          </View>
          <AdaptiveGlass style={styles.headerCount}>
            <Text style={[styles.headerCountText, { color: palette.text }]}>{cars.filter((car) => !['hidden', 'sold'].includes(car.status)).length}</Text>
          </AdaptiveGlass>
        </View>

        <View style={[styles.search, { backgroundColor: palette.surface, borderColor: palette.hairline }]}>
          <SymbolView name={{ ios: 'magnifyingglass', android: 'search', web: 'search' }} size={18} tintColor={palette.secondary} />
          <TextInput
            value={query}
            onChangeText={setQuery}
            placeholder="Марка, модель или комплектация"
            placeholderTextColor={palette.tertiary as string}
            style={[styles.searchInput, { color: palette.text }]}
            autoCapitalize="none"
            autoCorrect={false}
            returnKeyType="search"
          />
          {query ? (
            <Pressable onPress={() => setQuery('')} hitSlop={10}>
              <SymbolView name={{ ios: 'xmark.circle.fill', android: 'cancel', web: 'cancel' }} size={18} tintColor={palette.tertiary} />
            </Pressable>
          ) : null}
        </View>

        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filterRail}>
          {statusFilters.map((item) => {
            const active = status === item.key;
            return (
              <Pressable key={item.key} onPress={() => setStatus(item.key)} style={({ pressed }) => pressed && styles.pressed}>
                {active ? (
                  <View style={[styles.filterPill, { backgroundColor: palette.text }]}>
                    <Text style={[styles.filterText, { color: palette.background }]}>{item.label}</Text>
                  </View>
                ) : (
                  <AdaptiveGlass interactive style={styles.filterPill}>
                    <Text style={[styles.filterText, { color: palette.text }]}>{item.label}</Text>
                  </AdaptiveGlass>
                )}
              </Pressable>
            );
          })}
        </ScrollView>

        <View style={styles.brandHeader}>
          <Text style={[styles.brandHeaderTitle, { color: palette.text }]}>Марки</Text>
          <Text style={[styles.resultCount, { color: palette.secondary }]}>{filtered.length} авто</Text>
        </View>

        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.brandRail}>
          {brands.map((item) => {
            const active = brand === item;
            return (
              <Pressable key={item} onPress={() => setBrand(item)} style={({ pressed }) => pressed && styles.pressed}>
                <View style={[styles.brandPill, { backgroundColor: active ? palette.text : palette.surface, borderColor: active ? palette.text : palette.hairline }]}>
                  <Text style={[styles.brandText, { color: active ? palette.background : palette.text }]}>{item}</Text>
                </View>
              </Pressable>
            );
          })}
        </ScrollView>

        <View style={styles.resultHeader}>
          <View>
            <Text style={[styles.resultKicker, { color: palette.secondary }]}>SELECTION</Text>
            <Text style={[styles.resultTitle, { color: palette.text }]}>{status === 'showroom' ? 'В шоуруме' : status === 'stock' ? 'В наличии' : status === 'transit' ? 'В пути' : 'Все автомобили'}</Text>
          </View>
          <AdaptiveGlass style={styles.sortButton}>
            <SymbolView name={{ ios: 'line.3.horizontal.decrease', android: 'filter_list', web: 'filter_list' }} size={17} tintColor={palette.text} weight="semibold" />
          </AdaptiveGlass>
        </View>

        {loading ? <ActivityIndicator style={styles.loader} /> : null}

        {!loading && filtered.length === 0 ? (
          <View style={[styles.empty, { backgroundColor: palette.surface, borderColor: palette.hairline }]}>
            <SymbolView name={{ ios: 'car', android: 'directions_car', web: 'directions_car' }} size={28} tintColor={palette.secondary} />
            <Text style={[styles.emptyTitle, { color: palette.text }]}>Ничего не найдено</Text>
            <Text style={[styles.emptyText, { color: palette.secondary }]}>Измените поиск, марку или статус.</Text>
          </View>
        ) : null}

        <View style={styles.list}>
          {filtered.map((car) => <CarCard key={car.id} car={car} />)}
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { width: '100%', paddingHorizontal: 16, paddingTop: 22, paddingBottom: 128 },
  shell: { width: '100%', maxWidth: 720, alignSelf: 'center' },
  pressed: { opacity: 0.78 },
  headerRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 14 },
  headerCopy: { flex: 1 },
  kicker: { fontSize: 9, lineHeight: 12, fontWeight: '700', letterSpacing: 1.55 },
  title: { marginTop: 7, fontSize: 40, lineHeight: 43, fontWeight: '700', letterSpacing: -1.65 },
  subtitle: { marginTop: 8, maxWidth: 490, fontSize: 15, lineHeight: 21 },
  headerCount: { width: 44, height: 44, borderRadius: 22, alignItems: 'center', justifyContent: 'center' },
  headerCountText: { fontSize: 14, lineHeight: 18, fontWeight: '700' },
  search: { marginTop: 25, minHeight: 50, borderRadius: 25, borderWidth: StyleSheet.hairlineWidth, paddingHorizontal: 15, flexDirection: 'row', alignItems: 'center', gap: 10 },
  searchInput: { flex: 1, minHeight: 48, fontSize: 16, letterSpacing: -0.18, outlineStyle: 'none' } as any,
  filterRail: { paddingTop: 12, paddingRight: 16, gap: 8 },
  filterPill: { minHeight: 38, borderRadius: 19, paddingHorizontal: 14, alignItems: 'center', justifyContent: 'center' },
  filterText: { fontSize: 12, lineHeight: 15, fontWeight: '600' },
  brandHeader: { marginTop: 31, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 16 },
  brandHeaderTitle: { fontSize: 20, lineHeight: 24, fontWeight: '700', letterSpacing: -0.4 },
  resultCount: { fontSize: 12, lineHeight: 16, fontWeight: '500' },
  brandRail: { paddingTop: 12, paddingRight: 16, gap: 8 },
  brandPill: { minHeight: 38, borderRadius: 19, borderWidth: StyleSheet.hairlineWidth, paddingHorizontal: 14, alignItems: 'center', justifyContent: 'center' },
  brandText: { fontSize: 12, lineHeight: 15, fontWeight: '600' },
  resultHeader: { marginTop: 42, marginBottom: 20, flexDirection: 'row', alignItems: 'flex-end', justifyContent: 'space-between', gap: 16 },
  resultKicker: { marginBottom: 4, fontSize: 9, lineHeight: 12, fontWeight: '700', letterSpacing: 1.45 },
  resultTitle: { fontSize: 28, lineHeight: 32, fontWeight: '700', letterSpacing: -0.85 },
  sortButton: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
  loader: { marginVertical: 40 },
  list: { width: '100%' },
  empty: { marginTop: 12, borderRadius: 28, borderWidth: StyleSheet.hairlineWidth, padding: 24, alignItems: 'center' },
  emptyTitle: { marginTop: 13, fontSize: 18, lineHeight: 22, fontWeight: '700' },
  emptyText: { marginTop: 5, fontSize: 14, lineHeight: 20 },
});
