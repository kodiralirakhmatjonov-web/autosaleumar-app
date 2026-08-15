import { Image } from 'expo-image';
import { router } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Linking,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
  useColorScheme,
} from 'react-native';
import { AdaptiveGlass } from '@/src/components/AdaptiveGlass';
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
const REQUEST_URL = 'https://autosaleumar.com/request-car/';

function SectionHeading({ title, action, kicker }: { title: string; action?: () => void; kicker?: string }) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  return (
    <View style={styles.sectionHeading}>
      <View style={styles.sectionTitleCopy}>
        {kicker ? <Text style={[styles.sectionKicker, { color: palette.secondary }]}>{kicker}</Text> : null}
        <Text style={[styles.sectionTitle, { color: palette.text }]}>{title}</Text>
      </View>
      {action ? (
        <Pressable accessibilityRole="button" onPress={action} hitSlop={10} style={({ pressed }) => pressed && styles.pressed}>
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
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={({ pressed }) => [styles.quickAction, pressed && styles.pressed]}>
      <AdaptiveGlass interactive style={styles.quickActionGlass}>
        <SymbolView
          name={{
            ios: symbol,
            android: symbol === 'car.fill' ? 'directions_car' : symbol === 'location.fill' ? 'location_on' : 'auto_awesome',
            web: symbol === 'car.fill' ? 'directions_car' : symbol === 'location.fill' ? 'location_on' : 'auto_awesome',
          }}
          size={20}
          tintColor={palette.text}
          weight="semibold"
        />
        <Text style={[styles.quickActionText, { color: palette.text }]}>{label}</Text>
      </AdaptiveGlass>
    </Pressable>
  );
}

function StatusMetric({ label, value, symbol, tone = 'green' }: { label: string; value: number; symbol: 'building.2.fill' | 'car.fill' | 'shippingbox.fill'; tone?: 'green' | 'orange' | 'blue' }) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const dot = tone === 'orange' ? '#FF9F0A' : tone === 'blue' ? '#0A84FF' : '#30D158';
  return (
    <View style={[styles.metricCard, { backgroundColor: palette.surface, borderColor: palette.hairline }]}>
      <View style={styles.metricTop}>
        <View style={[styles.metricIcon, { backgroundColor: palette.fill }]}>
          <SymbolView
            name={{ ios: symbol, android: symbol === 'building.2.fill' ? 'storefront' : symbol === 'shippingbox.fill' ? 'local_shipping' : 'directions_car', web: symbol === 'building.2.fill' ? 'storefront' : symbol === 'shippingbox.fill' ? 'local_shipping' : 'directions_car' }}
            size={17}
            tintColor={palette.text}
            weight="semibold"
          />
        </View>
        <View style={[styles.liveDot, { backgroundColor: dot }]} />
      </View>
      <Text style={[styles.metricValue, { color: palette.text }]}>{value}</Text>
      <Text style={[styles.metricLabel, { color: palette.secondary }]}>{label}</Text>
    </View>
  );
}

function CarRail({ cars }: { cars: CatalogCar[] }) {
  if (!cars.length) return null;
  return (
    <ScrollView horizontal showsHorizontalScrollIndicator={false} decelerationRate="fast" contentContainerStyle={styles.railContent}>
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
          <View>
            <Image source={dark ? require('@/assets/wordmark-white.png') : require('@/assets/wordmark-black.png')} contentFit="contain" style={styles.wordmark} />
            <Text style={[styles.locationLabel, { color: palette.secondary }]}>TASHKENT · SHOWROOM</Text>
          </View>
          <AdaptiveGlass interactive style={styles.catalogBadge}>
            <View style={styles.catalogBadgeInner}>
              <View style={styles.greenDot} />
              <Text style={[styles.catalogBadgeText, { color: palette.text }]}>{available.length || '—'} авто</Text>
            </View>
          </AdaptiveGlass>
        </View>

        <View style={styles.heroIntro}>
          <Text style={[styles.heroEyebrow, { color: palette.secondary }]}>AUTO SALE UMAR</Text>
          <Text style={[styles.heroTitle, { color: palette.text }]}>Ваш автомобиль.{"\n"}Под контролем.</Text>
          <Text style={[styles.heroSubtitle, { color: palette.secondary }]}>В наличии, в шоуруме и в пути — в одной системе.</Text>
        </View>

        {loading ? <ActivityIndicator style={styles.loader} /> : null}
        {error ? <Text style={[styles.error, { color: palette.secondary }]}>{error}</Text> : null}

        {featured ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={`Открыть ${featured.brand} ${featured.model}`}
            onPress={() => router.push({ pathname: '/car/[slug]', params: { slug: featured.slug } })}
            style={({ pressed }) => [styles.featuredPressable, pressed && styles.pressed]}
          >
            <View style={[styles.featuredStage, { backgroundColor: palette.surface, borderColor: palette.hairline }]}>
              {featuredImage ? <Image source={featuredImage} contentFit="contain" transition={180} style={StyleSheet.absoluteFill} /> : null}
              <AdaptiveGlass style={styles.heroStatus}>
                <View style={styles.heroStatusInner}>
                  <View style={styles.greenDot} />
                  <Text style={[styles.heroStatusText, { color: palette.text }]}>{statusLabel(featured.status)}</Text>
                </View>
              </AdaptiveGlass>
              {featured.year ? (
                <AdaptiveGlass style={styles.heroYear}>
                  <Text style={[styles.heroYearText, { color: palette.text }]}>{featured.year}</Text>
                </AdaptiveGlass>
              ) : null}
            </View>

            <AdaptiveGlass interactive style={styles.featuredGlass}>
              <View style={styles.featuredGlassContent}>
                <View style={styles.featuredCopy}>
                  <Text style={[styles.featuredBrand, { color: palette.secondary }]}>{featured.brand.toUpperCase()}</Text>
                  <Text numberOfLines={1} style={[styles.featuredModel, { color: palette.text }]}>{featured.model}</Text>
                  <Text numberOfLines={1} style={[styles.featuredMeta, { color: palette.secondary }]}>{[featured.trim, featured.engineText].filter(Boolean).join(' · ')}</Text>
                  <Text style={[styles.featuredPrice, { color: palette.text }]}>{formatPrice(featured)}</Text>
                </View>
                <View style={[styles.heroArrow, { backgroundColor: dark ? '#FFFFFF' : '#111111' }]}>
                  <SymbolView name={{ ios: 'arrow.up.right', android: 'north_east', web: 'north_east' }} size={17} tintColor={dark ? '#111111' : '#FFFFFF'} weight="semibold" />
                </View>
              </View>
            </AdaptiveGlass>
          </Pressable>
        ) : null}

        <View style={styles.quickActions}>
          <QuickAction label="Каталог" symbol="car.fill" onPress={() => router.push('/catalog')} />
          <QuickAction label="Шоурум" symbol="location.fill" onPress={() => void Linking.openURL(YANDEX_MAPS)} />
          <QuickAction label="Подбор" symbol="sparkles" onPress={() => void Linking.openURL(REQUEST_URL)} />
        </View>

        <View style={styles.section}>
          <SectionHeading kicker="LIVE" title="Сейчас" />
          <View style={styles.metricsRow}>
            <StatusMetric label="В шоуруме" value={showroom.length} symbol="building.2.fill" />
            <StatusMetric label="В наличии" value={stock.length} symbol="car.fill" tone="blue" />
            <StatusMetric label="В пути" value={transit.length} symbol="shippingbox.fill" tone="orange" />
          </View>
        </View>

        {showroom.length ? (
          <View style={styles.section}>
            <SectionHeading kicker="SHOWROOM" title="Можно увидеть сегодня" action={() => router.push('/catalog')} />
            <CarRail cars={showroom} />
          </View>
        ) : null}

        {transit.length ? (
          <Pressable onPress={() => router.push('/catalog')} style={({ pressed }) => [styles.routePressable, pressed && styles.pressed]}>
            <View style={[styles.routeCard, { backgroundColor: palette.surface, borderColor: palette.hairline }]}>
              <View style={styles.routeHeader}>
                <View>
                  <Text style={[styles.routeKicker, { color: palette.secondary }]}>СТАТУС ПОСТАВКИ</Text>
                  <Text style={[styles.routeTitle, { color: palette.text }]}>{transit.length} авто в пути</Text>
                </View>
                <AdaptiveGlass interactive style={styles.routeArrow}>
                  <SymbolView name={{ ios: 'chevron.right', android: 'chevron_right', web: 'chevron_right' }} size={14} tintColor={palette.text} weight="semibold" />
                </AdaptiveGlass>
              </View>
              <View style={styles.routeTrack}>
                <View style={styles.routeStop}>
                  <View style={[styles.routeDot, { backgroundColor: palette.text }]} />
                  <Text style={[styles.routeCity, { color: palette.text }]}>Мир</Text>
                </View>
                <View style={[styles.routeLine, { backgroundColor: palette.hairline }]}>
                  <View style={styles.routeLineProgress} />
                </View>
                <View style={styles.routeStop}>
                  <View style={styles.routeDotDestination} />
                  <Text style={[styles.routeCity, { color: palette.text }]}>Ташкент</Text>
                </View>
              </View>
              <Text style={[styles.routeText, { color: palette.secondary }]}>Корея, ОАЭ, США, Канада и другие направления. Статусы обновляются в единой системе.</Text>
            </View>
          </Pressable>
        ) : null}

        <View style={styles.section}>
          <SectionHeading kicker="AUTO SALE UMAR" title="Шоурум" />
          <Pressable onPress={() => void Linking.openURL(YANDEX_MAPS)} style={({ pressed }) => pressed && styles.pressed}>
            <View style={[styles.showroomHero, { borderColor: palette.hairline }]}>
              <Image source={SHOWROOM_IMAGES[0]} contentFit="cover" transition={180} style={StyleSheet.absoluteFill} />
              <View style={styles.showroomShade} />
              <AdaptiveGlass dark style={styles.showroomGlass}>
                <View style={styles.showroomGlassInner}>
                  <View style={styles.showroomCopy}>
                    <Text style={styles.showroomTitle}>Приезжайте в шоурум</Text>
                    <Text style={styles.showroomText}>Ташкент · автомобили доступны для просмотра.</Text>
                  </View>
                  <View style={styles.showroomIcon}>
                    <SymbolView name={{ ios: 'location.fill', android: 'location_on', web: 'location_on' }} size={18} tintColor="#FFFFFF" />
                  </View>
                </View>
              </AdaptiveGlass>
            </View>
          </Pressable>
        </View>

        <Pressable onPress={() => void Linking.openURL(REQUEST_URL)} style={({ pressed }) => [styles.conciergePressable, pressed && styles.pressed]}>
          <View style={styles.conciergeCard}>
            <View style={styles.conciergeIcon}>
              <SymbolView name={{ ios: 'sparkles', android: 'auto_awesome', web: 'auto_awesome' }} size={22} tintColor="#FFFFFF" weight="semibold" />
            </View>
            <View style={styles.conciergeCopy}>
              <Text style={styles.conciergeKicker}>PERSONAL SELECTION</Text>
              <Text style={styles.conciergeTitle}>Найдём автомобиль под ваш запрос.</Text>
              <Text style={styles.conciergeText}>Модель, комплектация, бюджет и страна — оставьте запрос, остальное соберём в одном процессе.</Text>
            </View>
            <View style={styles.conciergeArrow}>
              <SymbolView name={{ ios: 'arrow.right', android: 'arrow_forward', web: 'arrow_forward' }} size={18} tintColor="#111111" weight="semibold" />
            </View>
          </View>
        </Pressable>

        <View style={styles.footer}>
          <Image source={dark ? require('@/assets/wordmark-white.png') : require('@/assets/wordmark-black.png')} contentFit="contain" style={styles.footerLogo} />
          <Text style={[styles.footerText, { color: palette.tertiary }]}>Единая цифровая экосистема автомобилей</Text>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { width: '100%', paddingHorizontal: 16, paddingTop: 18, paddingBottom: 132 },
  shell: { width: '100%', maxWidth: 720, alignSelf: 'center' },
  pressed: { opacity: 0.84, transform: [{ scale: 0.992 }] },
  topbar: { minHeight: 54, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 16 },
  wordmark: { width: 150, height: 30 },
  locationLabel: { marginTop: 2, fontSize: 9, lineHeight: 12, fontWeight: '700', letterSpacing: 1.6 },
  catalogBadge: { minHeight: 38, borderRadius: 19, paddingHorizontal: 13, justifyContent: 'center' },
  catalogBadgeInner: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  catalogBadgeText: { fontSize: 12, lineHeight: 15, fontWeight: '600' },
  greenDot: { width: 7, height: 7, borderRadius: 4, backgroundColor: '#30D158' },
  heroIntro: { paddingTop: 38, paddingBottom: 24 },
  heroEyebrow: { fontSize: 10, lineHeight: 13, fontWeight: '700', letterSpacing: 1.7 },
  heroTitle: { marginTop: 8, maxWidth: 570, fontSize: 43, lineHeight: 44, fontWeight: '700', letterSpacing: -1.8 },
  heroSubtitle: { marginTop: 12, maxWidth: 500, fontSize: 16, lineHeight: 23, letterSpacing: -0.16 },
  loader: { marginVertical: 28 },
  error: { marginBottom: 18, fontSize: 14, lineHeight: 20 },
  featuredPressable: { width: '100%' },
  featuredStage: { width: '100%', aspectRatio: 1.16, borderRadius: 36, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden' },
  heroStatus: { position: 'absolute', top: 15, left: 15, minHeight: 36, borderRadius: 18, paddingHorizontal: 13, justifyContent: 'center' },
  heroStatusInner: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  heroStatusText: { fontSize: 12, lineHeight: 15, fontWeight: '600' },
  heroYear: { position: 'absolute', top: 15, right: 15, minHeight: 36, borderRadius: 18, paddingHorizontal: 13, justifyContent: 'center' },
  heroYearText: { fontSize: 12, lineHeight: 15, fontWeight: '600' },
  featuredGlass: { marginTop: -58, marginHorizontal: 14, minHeight: 132, borderRadius: 30, padding: 18 },
  featuredGlassContent: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  featuredCopy: { flex: 1 },
  featuredBrand: { fontSize: 10, lineHeight: 13, fontWeight: '700', letterSpacing: 1.0 },
  featuredModel: { marginTop: 4, fontSize: 26, lineHeight: 30, fontWeight: '700', letterSpacing: -0.8 },
  featuredMeta: { marginTop: 3, fontSize: 13, lineHeight: 18 },
  featuredPrice: { marginTop: 10, fontSize: 17, lineHeight: 21, fontWeight: '700', letterSpacing: -0.28 },
  heroArrow: { width: 46, height: 46, borderRadius: 23, alignItems: 'center', justifyContent: 'center' },
  quickActions: { marginTop: 20, flexDirection: 'row', gap: 9 },
  quickAction: { flex: 1 },
  quickActionGlass: { minHeight: 48, borderRadius: 24, paddingHorizontal: 10, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 7 },
  quickActionText: { fontSize: 12, lineHeight: 15, fontWeight: '600' },
  section: { paddingTop: 46 },
  sectionHeading: { minHeight: 42, marginBottom: 17, flexDirection: 'row', alignItems: 'flex-end', justifyContent: 'space-between', gap: 16 },
  sectionTitleCopy: { flex: 1 },
  sectionKicker: { marginBottom: 5, fontSize: 9, lineHeight: 12, fontWeight: '700', letterSpacing: 1.45 },
  sectionTitle: { fontSize: 29, lineHeight: 33, fontWeight: '700', letterSpacing: -0.9 },
  sectionActionInner: { minHeight: 28, flexDirection: 'row', alignItems: 'center', gap: 4 },
  sectionAction: { fontSize: 15, lineHeight: 20, fontWeight: '500' },
  metricsRow: { flexDirection: 'row', gap: 9 },
  metricCard: { flex: 1, minHeight: 136, borderRadius: 26, borderWidth: StyleSheet.hairlineWidth, padding: 14 },
  metricTop: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  metricIcon: { width: 34, height: 34, borderRadius: 17, alignItems: 'center', justifyContent: 'center' },
  liveDot: { width: 7, height: 7, borderRadius: 4 },
  metricValue: { marginTop: 19, fontSize: 28, lineHeight: 30, fontWeight: '700', letterSpacing: -0.8 },
  metricLabel: { marginTop: 4, fontSize: 11, lineHeight: 15, fontWeight: '500' },
  railContent: { gap: 14, paddingRight: 18 },
  routePressable: { paddingTop: 46 },
  routeCard: { borderRadius: 30, borderWidth: StyleSheet.hairlineWidth, padding: 20 },
  routeHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 14 },
  routeKicker: { fontSize: 9, lineHeight: 12, fontWeight: '700', letterSpacing: 1.45 },
  routeTitle: { marginTop: 5, fontSize: 22, lineHeight: 26, fontWeight: '700', letterSpacing: -0.55 },
  routeArrow: { width: 38, height: 38, borderRadius: 19, alignItems: 'center', justifyContent: 'center' },
  routeTrack: { marginTop: 24, flexDirection: 'row', alignItems: 'flex-start' },
  routeStop: { width: 56, alignItems: 'center' },
  routeDot: { width: 12, height: 12, borderRadius: 6 },
  routeDotDestination: { width: 12, height: 12, borderRadius: 6, backgroundColor: '#30D158', borderWidth: 3, borderColor: 'rgba(48,209,88,0.22)' },
  routeCity: { marginTop: 7, fontSize: 11, lineHeight: 14, fontWeight: '600' },
  routeLine: { flex: 1, height: 2, marginTop: 5 },
  routeLineProgress: { width: '70%', height: 2, backgroundColor: '#30D158' },
  routeText: { marginTop: 20, fontSize: 13, lineHeight: 19 },
  showroomHero: { width: '100%', aspectRatio: 1.1, borderRadius: 32, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden', justifyContent: 'flex-end' },
  showroomShade: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(0,0,0,0.15)' },
  showroomGlass: { margin: 14, minHeight: 98, borderRadius: 25, padding: 15 },
  showroomGlassInner: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  showroomCopy: { flex: 1 },
  showroomTitle: { color: '#FFFFFF', fontSize: 20, lineHeight: 24, fontWeight: '700', letterSpacing: -0.45 },
  showroomText: { marginTop: 4, color: 'rgba(255,255,255,0.78)', fontSize: 12, lineHeight: 17 },
  showroomIcon: { width: 42, height: 42, borderRadius: 21, backgroundColor: 'rgba(255,255,255,0.14)', alignItems: 'center', justifyContent: 'center' },
  conciergePressable: { paddingTop: 46 },
  conciergeCard: { minHeight: 210, borderRadius: 34, padding: 22, backgroundColor: '#111113', overflow: 'hidden' },
  conciergeIcon: { width: 46, height: 46, borderRadius: 23, backgroundColor: 'rgba(255,255,255,0.12)', alignItems: 'center', justifyContent: 'center' },
  conciergeCopy: { maxWidth: 520, paddingTop: 25, paddingRight: 56 },
  conciergeKicker: { color: 'rgba(255,255,255,0.55)', fontSize: 9, lineHeight: 12, fontWeight: '700', letterSpacing: 1.5 },
  conciergeTitle: { marginTop: 7, color: '#FFFFFF', fontSize: 27, lineHeight: 31, fontWeight: '700', letterSpacing: -0.75 },
  conciergeText: { marginTop: 9, color: 'rgba(255,255,255,0.65)', fontSize: 13, lineHeight: 19 },
  conciergeArrow: { position: 'absolute', right: 20, bottom: 20, width: 44, height: 44, borderRadius: 22, backgroundColor: '#FFFFFF', alignItems: 'center', justifyContent: 'center' },
  footer: { paddingTop: 52, paddingBottom: 4 },
  footerLogo: { width: 112, height: 23 },
  footerText: { marginTop: 8, fontSize: 11, lineHeight: 15 },
});
