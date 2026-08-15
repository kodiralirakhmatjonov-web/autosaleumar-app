import { GlassView, isGlassEffectAPIAvailable } from 'expo-glass-effect';
import { Image } from 'expo-image';
import { router } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Linking,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
  useColorScheme,
} from 'react-native';
import { CarCard } from '@/src/components/CarCard';
import { absoluteMediaUrl, getCatalog } from '@/src/lib/api';
import { formatPrice, statusLabel } from '@/src/lib/format';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

const SHOWROOM_IMAGES = [
  'https://autosaleumar.com/showroom/showroom-01.webp',
  'https://autosaleumar.com/showroom/showroom-02.webp',
];

const YANDEX_MAPS = 'https://yandex.ru/maps/org/auto_sale_umar/98317002086';

function SectionHeading({ title, action }: { title: string; action?: () => void }) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  return (
    <View style={styles.sectionHeading}>
      <Text style={[styles.sectionTitle, { color: palette.text }]}>{title}</Text>
      {action ? (
        <Pressable accessibilityRole="button" onPress={action} hitSlop={10}>
          <View style={styles.sectionActionInner}>
            <Text style={[styles.sectionAction, { color: palette.accent }]}>Все</Text>
            <SymbolView name={{ ios: 'chevron.right', android: 'chevron_right', web: 'chevron_right' }} size={12} tintColor={palette.accent} weight="semibold" />
          </View>
        </Pressable>
      ) : null}
    </View>
  );
}

function QuickAction({
  label,
  symbol,
  onPress,
}: {
  label: string;
  symbol: 'car.fill' | 'location.fill' | 'sparkles';
  onPress: () => void;
}) {
  const dark = useColorScheme() === 'dark';
  const palette = colors[dark ? 'dark' : 'light'];
  const nativeGlass = Platform.OS === 'ios' && isGlassEffectAPIAvailable();

  const icon = (
    <SymbolView
      name={{
        ios: symbol,
        android: symbol === 'car.fill' ? 'directions_car' : symbol === 'location.fill' ? 'location_on' : 'auto_awesome',
        web: symbol === 'car.fill' ? 'directions_car' : symbol === 'location.fill' ? 'location_on' : 'auto_awesome',
      }}
      size={21}
      tintColor={palette.text}
      weight="semibold"
    />
  );

  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={({ pressed }) => [styles.quickAction, pressed && styles.pressed]}>
      {nativeGlass ? (
        <GlassView isInteractive glassEffectStyle="regular" style={styles.quickActionCircle}>{icon}</GlassView>
      ) : (
        <View style={[styles.quickActionCircle, styles.fallbackGlass, { borderColor: palette.hairline }]}>{icon}</View>
      )}
      <Text style={[styles.quickActionLabel, { color: palette.secondary }]}>{label}</Text>
    </Pressable>
  );
}

function CarRail({ cars }: { cars: CatalogCar[] }) {
  if (!cars.length) return null;
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      decelerationRate="fast"
      snapToAlignment="start"
      contentContainerStyle={styles.railContent}
    >
      {cars.slice(0, 8).map((car) => <CarCard key={car.id} car={car} variant="rail" />)}
    </ScrollView>
  );
}

export default function HomeScreen() {
  const dark = useColorScheme() === 'dark';
  const palette = colors[dark ? 'dark' : 'light'];
  const [cars, setCars] = useState<CatalogCar[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      setError(null);
      setCars(await getCatalog(100));
    } catch {
      setError('Не удалось обновить каталог. Потяните вниз, чтобы повторить.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const available = useMemo(() => cars.filter((car) => !['sold', 'hidden'].includes(car.status)), [cars]);
  const featured = useMemo(() => available.find((car) => car.isFeatured) ?? available[0] ?? null, [available]);
  const showroom = useMemo(() => available.filter((car) => car.status === 'in_showroom'), [available]);
  const stock = useMemo(() => available.filter((car) => car.status === 'in_stock' || car.status === 'in_showroom'), [available]);
  const transit = useMemo(() => available.filter((car) => car.status === 'in_transit' || car.status === 'made_to_order'), [available]);
  const featuredImage = featured ? absoluteMediaUrl(featured.coverUrl ?? featured.variants?.[0]?.photos?.[0]?.url) : null;

  return (
    <ScrollView
      style={{ backgroundColor: palette.background }}
      contentInsetAdjustmentBehavior="automatic"
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); void load(); }} />}
      contentContainerStyle={styles.content}
    >
      <View style={styles.shell}>
        <View style={styles.topbar}>
          <Image
            source={dark ? require('@/assets/wordmark-white.png') : require('@/assets/wordmark-black.png')}
            contentFit="contain"
            style={styles.wordmark}
          />
          <Pressable onPress={() => router.push('/more')} style={({ pressed }) => pressed && styles.pressed}>
            <View style={[styles.profileButton, { backgroundColor: palette.fill }]}>
              <SymbolView name={{ ios: 'ellipsis.circle.fill', android: 'more_horiz', web: 'more_horiz' }} size={25} tintColor={palette.secondary} />
            </View>
          </Pressable>
        </View>

        <View style={styles.welcomeRow}>
          <View style={styles.welcomeCopy}>
            <Text style={[styles.largeTitle, { color: palette.text }]}>Добро пожаловать</Text>
            <Text style={[styles.introText, { color: palette.secondary }]}>Выберите автомобиль в своём ритме.</Text>
          </View>
          <Text style={[styles.catalogCount, { color: palette.secondary }]}>{available.length ? `${available.length} авто` : 'Каталог'}</Text>
        </View>

        <View style={styles.quickActions}>
          <QuickAction label="Каталог" symbol="car.fill" onPress={() => router.push('/catalog')} />
          <QuickAction label="Шоурум" symbol="location.fill" onPress={() => void Linking.openURL(YANDEX_MAPS)} />
          <QuickAction label="Подбор" symbol="sparkles" onPress={() => void Linking.openURL('https://autosaleumar.com/request-car/')} />
        </View>

        {loading ? <ActivityIndicator style={styles.loader} /> : null}
        {error ? <Text style={[styles.error, { color: palette.secondary }]}>{error}</Text> : null}

        {featured ? (
          <View style={styles.featuredSection}>
            <SectionHeading title="Рекомендуем" />
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={`Открыть ${featured.brand} ${featured.model}`}
              onPress={() => router.push({ pathname: '/car/[slug]', params: { slug: featured.slug } })}
              style={({ pressed }) => pressed && styles.pressed}
            >
              <View style={[styles.featuredImageWrap, { backgroundColor: palette.elevated, borderColor: palette.hairline }]}> 
                {featuredImage ? <Image source={featuredImage} contentFit="contain" transition={160} style={StyleSheet.absoluteFill} /> : null}
                <View style={[styles.featuredStatus, styles.fallbackGlass, { borderColor: palette.hairline }]}>
                  <Text style={[styles.featuredStatusText, { color: palette.text }]}>{statusLabel(featured.status)}</Text>
                </View>
              </View>

              <View style={styles.featuredCopy}>
                <View style={styles.featuredTopline}>
                  <Text style={[styles.featuredBrand, { color: palette.secondary }]}>{featured.brand.toUpperCase()}</Text>
                  {featured.year ? <Text style={[styles.featuredYear, { color: palette.tertiary }]}>{featured.year}</Text> : null}
                </View>
                <Text numberOfLines={1} style={[styles.featuredModel, { color: palette.text }]}>{featured.model}</Text>
                {featured.trim ? <Text numberOfLines={1} style={[styles.featuredTrim, { color: palette.secondary }]}>{featured.trim}</Text> : null}
                <View style={styles.featuredMeta}>
                  <Text style={[styles.featuredPrice, { color: palette.text }]}>{formatPrice(featured)}</Text>
                  <View style={[styles.detailButton, { backgroundColor: palette.fill }]}>
                    <Text style={[styles.detailButtonText, { color: palette.text }]}>Подробнее</Text>
                    <SymbolView name={{ ios: 'chevron.right', android: 'chevron_right', web: 'chevron_right' }} size={12} tintColor={palette.secondary} weight="semibold" />
                  </View>
                </View>
              </View>
            </Pressable>
          </View>
        ) : null}

        {showroom.length ? (
          <View style={styles.section}>
            <SectionHeading title="В шоуруме" action={() => router.push('/catalog')} />
            <CarRail cars={showroom} />
          </View>
        ) : null}

        {stock.length ? (
          <View style={styles.section}>
            <SectionHeading title="В наличии" action={() => router.push('/catalog')} />
            <CarRail cars={stock} />
          </View>
        ) : null}

        {transit.length ? (
          <View style={styles.section}>
            <SectionHeading title="В пути" action={() => router.push('/catalog')} />
            <CarRail cars={transit} />
          </View>
        ) : null}

        <View style={styles.section}>
          <SectionHeading title="Шоурум" />
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.showroomRail}>
            {SHOWROOM_IMAGES.map((image, index) => (
              <Pressable key={image} onPress={() => void Linking.openURL(YANDEX_MAPS)} style={({ pressed }) => pressed && styles.pressed}>
                <View style={[styles.showroomCard, { backgroundColor: palette.surface, borderColor: palette.hairline }]}> 
                  <Image source={image} contentFit="cover" transition={160} style={styles.showroomImage} />
                  <View style={styles.showroomCopy}>
                    <Text style={[styles.showroomTitle, { color: palette.text }]}>{index === 0 ? 'Посмотреть автомобили' : 'Запланировать визит'}</Text>
                    <Text numberOfLines={2} style={[styles.showroomText, { color: palette.secondary }]}>{index === 0 ? 'Коллекция Auto Sale Umar в Ташкенте.' : 'Откройте локацию шоурума в Яндекс Картах.'}</Text>
                  </View>
                </View>
              </Pressable>
            ))}
          </ScrollView>
        </View>

        <Pressable onPress={() => void Linking.openURL('https://autosaleumar.com/request-car/')} style={({ pressed }) => [styles.supplyPressable, pressed && styles.pressed]}>
          <View style={[styles.supplyCard, { backgroundColor: palette.surface, borderColor: palette.hairline }]}> 
            <View style={[styles.supplyIcon, { backgroundColor: palette.fill }]}>
              <SymbolView name={{ ios: 'globe', android: 'public', web: 'public' }} size={21} tintColor={palette.text} weight="medium" />
            </View>
            <View style={styles.supplyCopy}>
              <Text style={[styles.supplyTitle, { color: palette.text }]}>Найти автомобиль</Text>
              <Text style={[styles.supplyText, { color: palette.secondary }]}>США, Канада, Корея, ОАЭ и другие рынки.</Text>
            </View>
            <SymbolView name={{ ios: 'chevron.right', android: 'chevron_right', web: 'chevron_right' }} size={14} tintColor={palette.secondary} weight="semibold" />
          </View>
        </Pressable>

        <View style={styles.footer}>
          <Image source={dark ? require('@/assets/wordmark-white.png') : require('@/assets/wordmark-black.png')} contentFit="contain" style={styles.footerLogo} />
          <Text style={[styles.footerText, { color: palette.secondary }]}>Ташкент · © 2026</Text>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { width: '100%', paddingHorizontal: 18, paddingTop: 4, paddingBottom: 118 },
  shell: { width: '100%', maxWidth: 680, alignSelf: 'center' },
  topbar: { minHeight: 58, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 16 },
  wordmark: { width: 137, height: 29 },
  profileButton: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
  welcomeRow: { paddingTop: 15, paddingBottom: 18, flexDirection: 'row', alignItems: 'flex-end', justifyContent: 'space-between', gap: 16 },
  welcomeCopy: { flex: 1 },
  largeTitle: { fontSize: 34, lineHeight: 39, fontWeight: '700', letterSpacing: -1.15 },
  introText: { marginTop: 3, fontSize: 16, lineHeight: 22, letterSpacing: -0.18 },
  catalogCount: { fontSize: 13, lineHeight: 18, fontWeight: '500', paddingBottom: 2 },
  quickActions: { flexDirection: 'row', justifyContent: 'flex-start', gap: 26, marginBottom: 8 },
  quickAction: { width: 62, alignItems: 'center' },
  quickActionCircle: { width: 52, height: 52, borderRadius: 26, alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
  fallbackGlass: { backgroundColor: 'rgba(255,255,255,0.78)', borderWidth: StyleSheet.hairlineWidth },
  quickActionLabel: { marginTop: 6, fontSize: 11, lineHeight: 14, fontWeight: '500', letterSpacing: -0.1, textAlign: 'center' },
  pressed: { transform: [{ scale: 0.985 }], opacity: 0.91 },
  loader: { paddingVertical: 24 },
  error: { paddingVertical: 16, fontSize: 15, lineHeight: 21 },
  featuredSection: { paddingTop: 28 },
  section: { paddingTop: 40 },
  sectionHeading: { marginBottom: 14, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 16 },
  sectionTitle: { flex: 1, fontSize: 23, lineHeight: 28, fontWeight: '700', letterSpacing: -0.65 },
  sectionActionInner: { flexDirection: 'row', alignItems: 'center', gap: 3 },
  sectionAction: { fontSize: 14, lineHeight: 18, fontWeight: '500' },
  featuredImageWrap: { width: '100%', aspectRatio: 1.46, position: 'relative', borderRadius: 30, overflow: 'hidden', borderWidth: StyleSheet.hairlineWidth },
  featuredStatus: { position: 'absolute', left: 13, top: 13, minHeight: 31, paddingHorizontal: 11, borderRadius: 16, alignItems: 'center', justifyContent: 'center' },
  featuredStatusText: { fontSize: 11, lineHeight: 14, fontWeight: '600' },
  featuredCopy: { paddingHorizontal: 3, paddingTop: 13 },
  featuredTopline: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  featuredBrand: { flex: 1, fontSize: 10, lineHeight: 13, fontWeight: '700', letterSpacing: 0.8 },
  featuredModel: { marginTop: 3, fontSize: 26, lineHeight: 30, fontWeight: '700', letterSpacing: -0.8 },
  featuredTrim: { marginTop: 2, fontSize: 14, lineHeight: 19 },
  featuredYear: { fontSize: 12, lineHeight: 15, fontWeight: '500' },
  featuredMeta: { marginTop: 11, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  featuredPrice: { flex: 1, fontSize: 17, lineHeight: 21, fontWeight: '600', letterSpacing: -0.2 },
  detailButton: { minHeight: 34, borderRadius: 17, paddingHorizontal: 12, flexDirection: 'row', alignItems: 'center', gap: 4 },
  detailButtonText: { fontSize: 12, lineHeight: 16, fontWeight: '600' },
  railContent: { gap: 14, paddingRight: 8 },
  showroomRail: { gap: 12, paddingRight: 8 },
  showroomCard: { width: 282, borderRadius: 26, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden' },
  showroomImage: { width: '100%', aspectRatio: 1.42 },
  showroomCopy: { padding: 15 },
  showroomTitle: { fontSize: 17, lineHeight: 21, fontWeight: '600', letterSpacing: -0.25 },
  showroomText: { marginTop: 4, fontSize: 13, lineHeight: 18 },
  supplyPressable: { paddingTop: 40 },
  supplyCard: { minHeight: 86, borderRadius: 25, borderWidth: StyleSheet.hairlineWidth, paddingHorizontal: 15, flexDirection: 'row', alignItems: 'center', gap: 12 },
  supplyIcon: { width: 44, height: 44, borderRadius: 22, alignItems: 'center', justifyContent: 'center' },
  supplyCopy: { flex: 1 },
  supplyTitle: { fontSize: 16, lineHeight: 20, fontWeight: '600', letterSpacing: -0.2 },
  supplyText: { marginTop: 2, fontSize: 13, lineHeight: 18 },
  footer: { paddingTop: 48, paddingBottom: 8, alignItems: 'flex-start' },
  footerLogo: { width: 112, height: 23 },
  footerText: { marginTop: 7, fontSize: 11, lineHeight: 15 },
});
