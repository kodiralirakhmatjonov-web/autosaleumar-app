import { Image } from 'expo-image';
import { router } from 'expo-router';
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
  useWindowDimensions,
} from 'react-native';
import { CarCard } from '@/src/components/CarCard';
import { GlassPill } from '@/src/components/GlassPill';
import { absoluteMediaUrl, getCatalog } from '@/src/lib/api';
import { formatPrice, statusLabel } from '@/src/lib/format';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

const SHOWROOM_IMAGES = [
  'https://autosaleumar.com/showroom/showroom-01.webp',
  'https://autosaleumar.com/showroom/showroom-02.webp',
  'https://autosaleumar.com/showroom/showroom-03.webp',
];

const MARKETS = ['🇺🇸 США', '🇨🇦 Канада', '🇰🇷 Корея', '🇦🇪 ОАЭ', '🇪🇺 Европа', '🇬🇧 Великобритания'];

function SectionHeading({ kicker, title, text }: { kicker: string; title: string; text?: string }) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  return (
    <View style={styles.sectionHeading}>
      <Text style={[styles.kicker, { color: palette.secondary }]}>{kicker}</Text>
      <Text style={[styles.sectionTitle, { color: palette.text }]}>{title}</Text>
      {text ? <Text style={[styles.sectionText, { color: palette.secondary }]}>{text}</Text> : null}
    </View>
  );
}

function CarRail({ cars }: { cars: CatalogCar[] }) {
  if (!cars.length) return null;
  return (
    <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.railContent}>
      {cars.slice(0, 8).map((car) => <CarCard key={car.id} car={car} variant="rail" />)}
    </ScrollView>
  );
}

export default function HomeScreen() {
  const scheme = useColorScheme() === 'dark' ? 'dark' : 'light';
  const palette = colors[scheme];
  const { width } = useWindowDimensions();
  const [cars, setCars] = useState<CatalogCar[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      setError(null);
      setCars(await getCatalog(100));
    } catch {
      setError('Каталог временно не загрузился. Потяните экран вниз, чтобы повторить.');
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
  const brands = useMemo(() => Array.from(new Set(available.map((car) => car.brand))).slice(0, 12), [available]);
  const featuredImage = featured ? absoluteMediaUrl(featured.coverUrl ?? featured.variants?.[0]?.photos?.[0]?.url) : null;
  const contentWidth = Math.min(width - 36, 760);

  return (
    <ScrollView
      style={{ backgroundColor: palette.background }}
      contentInsetAdjustmentBehavior="automatic"
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); void load(); }} />}
      contentContainerStyle={styles.content}
    >
      <View style={[styles.inner, { width: contentWidth }]}> 
        <View style={styles.topbar}>
          <Image
            source={scheme === 'dark' ? require('@/assets/wordmark-white.png') : require('@/assets/wordmark-black.png')}
            contentFit="contain"
            style={styles.wordmark}
          />
          <View style={[styles.liveDot, { backgroundColor: available.length ? '#30A46C' : palette.hairline }]} />
        </View>

        <View style={styles.heroCopy}>
          <Text style={[styles.kicker, { color: palette.secondary }]}>AUTO SALE UMAR · TASHKENT</Text>
          <Text style={[styles.heroTitle, { color: palette.text }]}>Автомобиль,{`\n`}выбранный точно.</Text>
          <Text style={[styles.heroText, { color: palette.secondary }]}>Новые автомобили в наличии и в пути. Международный подбор, прозрачный статус и персональное сопровождение.</Text>
        </View>

        {loading ? <ActivityIndicator style={styles.loader} /> : null}
        {error ? <Text style={[styles.error, { color: palette.secondary }]}>{error}</Text> : null}

        {featured ? (
          <Pressable
            onPress={() => router.push({ pathname: '/car/[slug]', params: { slug: featured.slug } })}
            style={({ pressed }) => [styles.featuredCard, { backgroundColor: palette.surface, borderColor: palette.hairline }, pressed && styles.pressed]}
          >
            <View style={[styles.featuredImageWrap, { backgroundColor: palette.surface }]}>
              {featuredImage ? <Image source={featuredImage} contentFit="cover" transition={240} style={StyleSheet.absoluteFill} /> : null}
              <View style={styles.featuredStatus}><Text style={styles.featuredStatusText}>{statusLabel(featured.status)}</Text></View>
            </View>
            <View style={styles.featuredCopy}>
              <View style={styles.featuredNameRow}>
                <View style={styles.featuredNameText}>
                  <Text style={[styles.featuredBrand, { color: palette.secondary }]}>{featured.brand.toUpperCase()}</Text>
                  <Text numberOfLines={2} style={[styles.featuredModel, { color: palette.text }]}>{featured.model}{featured.trim ? ` ${featured.trim}` : ''}</Text>
                </View>
                <Text style={[styles.featuredPrice, { color: palette.text }]}>{formatPrice(featured)}</Text>
              </View>
              <View style={styles.heroAction}>
                <GlassPill><Text style={[styles.glassLabel, { color: palette.text }]}>Открыть автомобиль</Text></GlassPill>
              </View>
            </View>
          </Pressable>
        ) : null}

        <View style={styles.section}>
          <SectionHeading kicker="ВЫБЕРИТЕ МАРКУ" title="Начните с характера." text="Коллекция формируется из автомобилей, которые действительно есть в общей базе Auto Sale Umar." />
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.brandRail}>
            {brands.map((brand) => (
              <Pressable
                key={brand}
                onPress={() => router.push({ pathname: '/catalog', params: { q: brand } })}
                style={({ pressed }) => [styles.brandPill, { backgroundColor: palette.surface, borderColor: palette.hairline }, pressed && styles.pressed]}
              >
                <Text style={[styles.brandPillText, { color: palette.text }]}>{brand}</Text>
              </Pressable>
            ))}
          </ScrollView>
        </View>

        {showroom.length ? (
          <View style={styles.section}>
            <SectionHeading kicker="В ШОУРУМЕ" title="Можно посмотреть сегодня." text="Автомобили, которые сейчас находятся в шоуруме и доступны для просмотра." />
            <CarRail cars={showroom} />
          </View>
        ) : null}

        {stock.length ? (
          <View style={styles.section}>
            <SectionHeading kicker="В НАЛИЧИИ" title="Без ожидания поставки." />
            <CarRail cars={stock} />
          </View>
        ) : null}

        {transit.length ? (
          <View style={styles.section}>
            <SectionHeading kicker="В ПУТИ" title="Следующее поступление." text="Автомобили, которые уже направляются в шоурум." />
            <CarRail cars={transit} />
          </View>
        ) : null}

        <View style={styles.section}>
          <SectionHeading kicker="О ШОУРУМЕ" title="Пространство для спокойного выбора." text="Автомобиль остаётся в центре внимания, а атмосфера даёт время рассмотреть детали без спешки." />
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.showroomRail}>
            {SHOWROOM_IMAGES.map((image, index) => (
              <View key={image} style={[styles.showroomCard, { backgroundColor: palette.surface, borderColor: palette.hairline }]}>
                <Image source={image} contentFit="cover" transition={200} style={styles.showroomImage} />
                <View style={styles.showroomCopy}>
                  <Text style={[styles.showroomTitle, { color: palette.text }]}>{['Коллекция вживую', 'Персональный просмотр', 'Auto Sale Umar · Tashkent'][index]}</Text>
                </View>
              </View>
            ))}
          </ScrollView>
        </View>

        <View style={styles.section}>
          <View style={[styles.deliveryCard, { backgroundColor: scheme === 'dark' ? '#121214' : '#111113' }]}>
            <Text style={styles.deliveryKicker}>МЕЖДУНАРОДНАЯ ПОСТАВКА</Text>
            <Text style={styles.deliveryTitle}>Ищем автомобиль там, где он есть.</Text>
            <Text style={styles.deliveryText}>Привозим новые автомобили под заказ и сохраняем понятный статус поставки на всём пути.</Text>
            <View style={styles.marketWrap}>{MARKETS.map((market) => <View key={market} style={styles.marketPill}><Text style={styles.marketText}>{market}</Text></View>)}</View>
          </View>
        </View>

        <View style={styles.section}>
          <View style={[styles.requestCard, { backgroundColor: palette.surface, borderColor: palette.hairline }]}>
            <Text style={[styles.kicker, { color: palette.secondary }]}>ПЕРСОНАЛЬНЫЙ ПОДБОР</Text>
            <Text style={[styles.requestTitle, { color: palette.text }]}>Не нашли нужный автомобиль?</Text>
            <Text style={[styles.sectionText, { color: palette.secondary }]}>Марка, модель, бюджет и срок покупки — команда Auto Sale Umar начнёт поиск под ваш запрос.</Text>
            <Pressable onPress={() => void Linking.openURL('https://autosaleumar.com/request-car/')} style={styles.requestButton}>
              <Text style={styles.requestButtonText}>Найти автомобиль</Text>
            </Pressable>
          </View>
        </View>

        <View style={styles.footer}>
          <Image
            source={scheme === 'dark' ? require('@/assets/wordmark-white.png') : require('@/assets/wordmark-black.png')}
            contentFit="contain"
            style={styles.footerLogo}
          />
          <Text style={[styles.footerText, { color: palette.secondary }]}>Премиальный автомобильный шоурум · Ташкент{`\n`}© 2026 Auto Sale Umar</Text>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { alignItems: 'center', paddingBottom: 110 },
  inner: { paddingHorizontal: 18, maxWidth: 760 },
  topbar: { minHeight: 76, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingTop: 8 },
  wordmark: { width: 180, height: 36 },
  liveDot: { width: 9, height: 9, borderRadius: 99 },
  heroCopy: { paddingTop: 34, paddingBottom: 28 },
  kicker: { fontSize: 11, fontWeight: '800', letterSpacing: 1.55 },
  heroTitle: { marginTop: 13, fontSize: 44, lineHeight: 44, fontWeight: '700', letterSpacing: -2.1 },
  heroText: { marginTop: 18, maxWidth: 570, fontSize: 17, lineHeight: 25, letterSpacing: -0.2 },
  loader: { paddingVertical: 28 },
  error: { paddingVertical: 18, fontSize: 15, lineHeight: 22 },
  featuredCard: { borderRadius: 38, overflow: 'hidden', borderWidth: StyleSheet.hairlineWidth },
  pressed: { transform: [{ scale: 0.985 }], opacity: 0.94 },
  featuredImageWrap: { position: 'relative', aspectRatio: 1.05 },
  featuredStatus: { position: 'absolute', left: 18, top: 18, paddingHorizontal: 13, paddingVertical: 8, borderRadius: 999, backgroundColor: 'rgba(14,14,15,0.68)' },
  featuredStatusText: { color: '#FFFFFF', fontSize: 12, fontWeight: '700' },
  featuredCopy: { padding: 20 },
  featuredNameRow: { flexDirection: 'row', alignItems: 'flex-end', justifyContent: 'space-between', gap: 14 },
  featuredNameText: { flex: 1 },
  featuredBrand: { fontSize: 12, fontWeight: '800', letterSpacing: 1 },
  featuredModel: { marginTop: 4, fontSize: 27, lineHeight: 30, fontWeight: '700', letterSpacing: -0.9 },
  featuredPrice: { fontSize: 18, fontWeight: '700', textAlign: 'right' },
  heroAction: { marginTop: 18, alignSelf: 'flex-start' },
  glassLabel: { fontSize: 15, fontWeight: '700' },
  section: { paddingTop: 74 },
  sectionHeading: { paddingRight: 8, marginBottom: 24 },
  sectionTitle: { marginTop: 10, fontSize: 35, lineHeight: 36, fontWeight: '700', letterSpacing: -1.55 },
  sectionText: { marginTop: 14, fontSize: 16, lineHeight: 24, maxWidth: 620 },
  railContent: { gap: 12, paddingRight: 18 },
  brandRail: { gap: 9, paddingRight: 18 },
  brandPill: { minHeight: 50, paddingHorizontal: 18, borderRadius: 999, borderWidth: StyleSheet.hairlineWidth, alignItems: 'center', justifyContent: 'center' },
  brandPillText: { fontSize: 14, fontWeight: '700' },
  showroomRail: { gap: 12, paddingRight: 18 },
  showroomCard: { width: 286, borderRadius: 32, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden' },
  showroomImage: { width: '100%', aspectRatio: 1.08 },
  showroomCopy: { padding: 16 },
  showroomTitle: { fontSize: 19, fontWeight: '700', letterSpacing: -0.4 },
  deliveryCard: { borderRadius: 38, padding: 24 },
  deliveryKicker: { color: 'rgba(255,255,255,0.58)', fontSize: 11, fontWeight: '800', letterSpacing: 1.45 },
  deliveryTitle: { marginTop: 11, color: '#FFFFFF', fontSize: 34, lineHeight: 36, fontWeight: '700', letterSpacing: -1.4 },
  deliveryText: { marginTop: 14, color: 'rgba(255,255,255,0.72)', fontSize: 16, lineHeight: 24 },
  marketWrap: { marginTop: 22, flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  marketPill: { paddingHorizontal: 12, paddingVertical: 9, borderRadius: 999, backgroundColor: 'rgba(255,255,255,0.1)', borderWidth: StyleSheet.hairlineWidth, borderColor: 'rgba(255,255,255,0.16)' },
  marketText: { color: '#FFFFFF', fontSize: 13, fontWeight: '600' },
  requestCard: { borderRadius: 38, padding: 24, borderWidth: StyleSheet.hairlineWidth },
  requestTitle: { marginTop: 10, fontSize: 31, lineHeight: 33, fontWeight: '700', letterSpacing: -1.2 },
  requestButton: { marginTop: 22, minHeight: 54, borderRadius: 999, alignItems: 'center', justifyContent: 'center', backgroundColor: '#111113' },
  requestButtonText: { color: '#FFFFFF', fontSize: 16, fontWeight: '700' },
  footer: { paddingTop: 82, paddingBottom: 28, alignItems: 'flex-start' },
  footerLogo: { width: 164, height: 33 },
  footerText: { marginTop: 13, fontSize: 13, lineHeight: 20 },
});
