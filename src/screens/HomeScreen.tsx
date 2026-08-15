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

function SectionHeading({
  eyebrow,
  title,
  action,
}: {
  eyebrow?: string;
  title: string;
  action?: () => void;
}) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  return (
    <View style={styles.sectionHeading}>
      <View style={styles.sectionHeadingCopy}>
        {eyebrow ? <Text style={[styles.eyebrow, { color: palette.secondary }]}>{eyebrow}</Text> : null}
        <Text style={[styles.sectionTitle, { color: palette.text }]}>{title}</Text>
      </View>
      {action ? (
        <Pressable accessibilityRole="button" onPress={action} hitSlop={10}>
          <Text style={[styles.sectionAction, { color: palette.accent }]}>Все</Text>
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

  const content = (
    <View style={styles.quickActionContent}>
      {Platform.OS === 'ios' ? (
        <SymbolView name={symbol} size={17} tintColor={palette.text} weight="semibold" />
      ) : null}
      <Text style={[styles.quickActionLabel, { color: palette.text }]}>{label}</Text>
    </View>
  );

  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.quickActionPressable, pressed && styles.pressed]}
    >
      {nativeGlass ? (
        <GlassView isInteractive glassEffectStyle="regular" style={styles.quickActionSurface}>
          {content}
        </GlassView>
      ) : (
        <View
          style={[
            styles.quickActionSurface,
            { backgroundColor: palette.surface, borderColor: palette.hairline },
          ]}
        >
          {content}
        </View>
      )}
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
      setError('Не удалось обновить каталог. Потяните экран вниз, чтобы повторить.');
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
          <Text style={[styles.catalogCount, { color: palette.secondary }]}>
            {available.length ? `${available.length} авто` : 'Каталог'}
          </Text>
        </View>

        <View style={styles.intro}>
          <Text style={[styles.largeTitle, { color: palette.text }]}>Автомобили</Text>
          <Text style={[styles.introText, { color: palette.secondary }]}>В наличии, в шоуруме и в пути.</Text>
        </View>

        <View style={styles.quickActions}>
          <QuickAction label="Каталог" symbol="car.fill" onPress={() => router.push('/catalog')} />
          <QuickAction label="Локация" symbol="location.fill" onPress={() => void Linking.openURL(YANDEX_MAPS)} />
          <QuickAction label="Подбор" symbol="sparkles" onPress={() => void Linking.openURL('https://autosaleumar.com/request-car/')} />
        </View>

        {loading ? <ActivityIndicator style={styles.loader} /> : null}
        {error ? <Text style={[styles.error, { color: palette.secondary }]}>{error}</Text> : null}

        {featured ? (
          <View style={styles.sectionCompact}>
            <SectionHeading eyebrow="РЕКОМЕНДУЕМ" title="Выбор сегодня" />
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={`Открыть ${featured.brand} ${featured.model}`}
              onPress={() => router.push({ pathname: '/car/[slug]', params: { slug: featured.slug } })}
              style={({ pressed }) => [
                styles.featuredCard,
                { backgroundColor: palette.surface, borderColor: palette.hairline },
                pressed && styles.pressed,
              ]}
            >
              <View style={[styles.featuredImageWrap, { backgroundColor: palette.elevated }]}> 
                {featuredImage ? <Image source={featuredImage} contentFit="contain" transition={180} style={StyleSheet.absoluteFill} /> : null}
                <View style={styles.featuredStatus}>
                  <Text style={styles.featuredStatusText}>{statusLabel(featured.status)}</Text>
                </View>
              </View>
              <View style={styles.featuredCopy}>
                <Text style={[styles.featuredBrand, { color: palette.secondary }]}>{featured.brand.toUpperCase()}</Text>
                <Text numberOfLines={1} style={[styles.featuredModel, { color: palette.text }]}>{featured.model}</Text>
                {featured.trim ? <Text numberOfLines={1} style={[styles.featuredTrim, { color: palette.secondary }]}>{featured.trim}</Text> : null}
                <View style={styles.featuredMeta}>
                  <Text style={[styles.featuredPrice, { color: palette.text }]}>{formatPrice(featured)}</Text>
                  {featured.year ? <Text style={[styles.featuredYear, { color: palette.secondary }]}>{featured.year}</Text> : null}
                </View>
              </View>
            </Pressable>
          </View>
        ) : null}

        {showroom.length ? (
          <View style={styles.section}>
            <SectionHeading eyebrow="В ШОУРУМЕ" title="Можно посмотреть сегодня" action={() => router.push('/catalog')} />
            <CarRail cars={showroom} />
          </View>
        ) : null}

        {stock.length ? (
          <View style={styles.section}>
            <SectionHeading eyebrow="В НАЛИЧИИ" title="Без ожидания поставки" action={() => router.push('/catalog')} />
            <CarRail cars={stock} />
          </View>
        ) : null}

        {transit.length ? (
          <View style={styles.section}>
            <SectionHeading eyebrow="В ПУТИ" title="Следующее поступление" action={() => router.push('/catalog')} />
            <CarRail cars={transit} />
          </View>
        ) : null}

        <View style={styles.section}>
          <SectionHeading eyebrow="ШОУРУМ" title="Auto Sale Umar · Tashkent" />
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.showroomRail}>
            {SHOWROOM_IMAGES.map((image, index) => (
              <View key={image} style={[styles.showroomCard, { backgroundColor: palette.surface, borderColor: palette.hairline }]}> 
                <Image source={image} contentFit="cover" transition={180} style={styles.showroomImage} />
                <View style={styles.showroomCopy}>
                  <Text style={[styles.showroomTitle, { color: palette.text }]}>{index === 0 ? 'Коллекция вживую' : 'Персональный просмотр'}</Text>
                  <Text style={[styles.showroomText, { color: palette.secondary }]}>{index === 0 ? 'Автомобили, которые уже в Ташкенте.' : 'Спокойно, без спешки и лишнего давления.'}</Text>
                </View>
              </View>
            ))}
          </ScrollView>
        </View>

        <View style={styles.section}>
          <View style={[styles.supplyCard, { backgroundColor: palette.surface, borderColor: palette.hairline }]}> 
            <Text style={[styles.eyebrow, { color: palette.secondary }]}>МЕЖДУНАРОДНАЯ ПОСТАВКА</Text>
            <Text style={[styles.supplyTitle, { color: palette.text }]}>Найдём нужную комплектацию.</Text>
            <Text style={[styles.supplyText, { color: palette.secondary }]}>США, Канада, Корея, ОАЭ и другие рынки. Статус автомобиля остаётся понятным на каждом этапе.</Text>
            <Pressable onPress={() => void Linking.openURL('https://autosaleumar.com/request-car/')} hitSlop={8}>
              <Text style={[styles.supplyLink, { color: palette.accent }]}>Оставить запрос</Text>
            </Pressable>
          </View>
        </View>

        <View style={styles.footer}>
          <Image source={dark ? require('@/assets/wordmark-white.png') : require('@/assets/wordmark-black.png')} contentFit="contain" style={styles.footerLogo} />
          <Text style={[styles.footerText, { color: palette.secondary }]}>Ташкент · © 2026</Text>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { width: '100%', paddingHorizontal: 20, paddingTop: 2, paddingBottom: 110 },
  shell: { width: '100%', maxWidth: 680, alignSelf: 'center' },
  topbar: { minHeight: 58, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 16 },
  wordmark: { width: 132, height: 27 },
  catalogCount: { fontSize: 13, lineHeight: 18, fontWeight: '500' },
  intro: { paddingTop: 16, paddingBottom: 18 },
  largeTitle: { fontSize: 34, lineHeight: 39, fontWeight: '700', letterSpacing: -1.15 },
  introText: { marginTop: 4, fontSize: 17, lineHeight: 23, letterSpacing: -0.2 },
  quickActions: { flexDirection: 'row', gap: 8, marginBottom: 10 },
  quickActionPressable: { flex: 1 },
  quickActionSurface: { minHeight: 48, borderRadius: 24, borderWidth: StyleSheet.hairlineWidth, alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
  quickActionContent: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 7, paddingHorizontal: 10 },
  quickActionLabel: { fontSize: 14, lineHeight: 18, fontWeight: '600', letterSpacing: -0.1 },
  pressed: { transform: [{ scale: 0.985 }], opacity: 0.92 },
  loader: { paddingVertical: 24 },
  error: { paddingVertical: 16, fontSize: 15, lineHeight: 21 },
  sectionCompact: { paddingTop: 26 },
  section: { paddingTop: 42 },
  sectionHeading: { marginBottom: 16, flexDirection: 'row', alignItems: 'flex-end', justifyContent: 'space-between', gap: 16 },
  sectionHeadingCopy: { flex: 1 },
  eyebrow: { fontSize: 11, lineHeight: 14, fontWeight: '700', letterSpacing: 1.15 },
  sectionTitle: { marginTop: 6, fontSize: 25, lineHeight: 29, fontWeight: '700', letterSpacing: -0.75 },
  sectionAction: { paddingBottom: 2, fontSize: 15, lineHeight: 20, fontWeight: '500' },
  featuredCard: { width: '100%', borderRadius: 28, overflow: 'hidden', borderWidth: StyleSheet.hairlineWidth },
  featuredImageWrap: { width: '100%', aspectRatio: 1.48, position: 'relative' },
  featuredStatus: { position: 'absolute', left: 14, top: 14, minHeight: 30, paddingHorizontal: 11, borderRadius: 15, alignItems: 'center', justifyContent: 'center', backgroundColor: 'rgba(0,0,0,0.68)' },
  featuredStatusText: { color: '#FFFFFF', fontSize: 12, lineHeight: 15, fontWeight: '600' },
  featuredCopy: { paddingHorizontal: 17, paddingTop: 15, paddingBottom: 17 },
  featuredBrand: { fontSize: 11, lineHeight: 14, fontWeight: '700', letterSpacing: 0.8 },
  featuredModel: { marginTop: 4, fontSize: 24, lineHeight: 28, fontWeight: '700', letterSpacing: -0.65 },
  featuredTrim: { marginTop: 2, fontSize: 15, lineHeight: 20 },
  featuredMeta: { marginTop: 11, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 14 },
  featuredPrice: { flex: 1, fontSize: 18, lineHeight: 22, fontWeight: '600', letterSpacing: -0.25 },
  featuredYear: { fontSize: 14, lineHeight: 19, fontWeight: '500' },
  railContent: { gap: 12, paddingRight: 8 },
  showroomRail: { gap: 12, paddingRight: 8 },
  showroomCard: { width: 286, borderRadius: 26, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden' },
  showroomImage: { width: '100%', aspectRatio: 1.42 },
  showroomCopy: { padding: 15 },
  showroomTitle: { fontSize: 18, lineHeight: 22, fontWeight: '600', letterSpacing: -0.3 },
  showroomText: { marginTop: 4, fontSize: 14, lineHeight: 19 },
  supplyCard: { borderRadius: 28, borderWidth: StyleSheet.hairlineWidth, padding: 20 },
  supplyTitle: { marginTop: 7, fontSize: 24, lineHeight: 28, fontWeight: '700', letterSpacing: -0.7 },
  supplyText: { marginTop: 10, fontSize: 15, lineHeight: 21 },
  supplyLink: { marginTop: 16, fontSize: 16, lineHeight: 21, fontWeight: '600' },
  footer: { paddingTop: 54, paddingBottom: 10, alignItems: 'flex-start' },
  footerLogo: { width: 118, height: 24 },
  footerText: { marginTop: 7, fontSize: 12, lineHeight: 16 },
});
