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
} from 'react-native';
import { AppleGlassButton } from '@/src/components/AppleGlassButton';
import { CarCard } from '@/src/components/CarCard';
import { absoluteMediaUrl, getCatalog } from '@/src/lib/api';
import { formatPrice, statusLabel } from '@/src/lib/format';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

const SHOWROOM_IMAGES = [
  'https://autosaleumar.com/showroom/showroom-01.webp',
  'https://autosaleumar.com/showroom/showroom-02.webp',
  'https://autosaleumar.com/showroom/showroom-03.webp',
];

const MARKETS = ['США', 'Канада', 'Корея', 'ОАЭ', 'Европа', 'Великобритания'];

function SectionHeading({ eyebrow, title, text }: { eyebrow?: string; title: string; text?: string }) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  return (
    <View style={styles.sectionHeading}>
      {eyebrow ? <Text style={[styles.eyebrow, { color: palette.secondary }]}>{eyebrow}</Text> : null}
      <Text style={[styles.sectionTitle, { color: palette.text }]}>{title}</Text>
      {text ? <Text style={[styles.sectionText, { color: palette.secondary }]}>{text}</Text> : null}
    </View>
  );
}

function CarRail({ cars }: { cars: CatalogCar[] }) {
  if (!cars.length) return null;
  return (
    <ScrollView
      horizontal
      style={styles.horizontalRail}
      showsHorizontalScrollIndicator={false}
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
      setError('Каталог временно недоступен. Потяните вниз, чтобы повторить.');
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
          <View style={[styles.liveStatus, { backgroundColor: palette.fill }]}> 
            <View style={[styles.liveDot, { backgroundColor: available.length ? '#30A46C' : palette.tertiary }]} />
            <Text style={[styles.liveText, { color: palette.secondary }]}>{available.length ? `${available.length} авто` : 'Каталог'}</Text>
          </View>
        </View>

        <View style={styles.heroCopy}>
          <Text style={[styles.eyebrow, { color: palette.secondary }]}>AUTO SALE UMAR · TASHKENT</Text>
          <Text style={[styles.heroTitle, { color: palette.text }]}>Автомобиль,{`\n`}выбранный точно.</Text>
          <Text style={[styles.heroText, { color: palette.secondary }]}>Новые автомобили в наличии и в пути. Один каталог, понятный статус и персональное сопровождение.</Text>
        </View>

        {loading ? <ActivityIndicator style={styles.loader} /> : null}
        {error ? <Text style={[styles.error, { color: palette.secondary }]}>{error}</Text> : null}

        {featured ? (
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
              <View style={[styles.statusPill, { backgroundColor: palette.fill }]}> 
                <Text style={[styles.statusText, { color: palette.text }]}>{statusLabel(featured.status)}</Text>
              </View>
            </View>
            <View style={styles.featuredCopy}>
              <Text style={[styles.featuredBrand, { color: palette.secondary }]}>{featured.brand.toUpperCase()}</Text>
              <Text style={[styles.featuredModel, { color: palette.text }]}>{featured.model}{featured.trim ? ` ${featured.trim}` : ''}</Text>
              <Text style={[styles.featuredPrice, { color: palette.text }]}>{formatPrice(featured)}</Text>
              <View style={styles.featuredAction}>
                <AppleGlassButton
                  label="Открыть автомобиль"
                  symbol={{ ios: 'arrow.right', android: 'arrow_forward', web: 'arrow_forward' }}
                />
              </View>
            </View>
          </Pressable>
        ) : null}

        {brands.length ? (
          <View style={styles.section}>
            <SectionHeading eyebrow="МАРКИ" title="Выберите характер." />
            <ScrollView horizontal style={styles.horizontalRail} showsHorizontalScrollIndicator={false} contentContainerStyle={styles.brandRail}>
              {brands.map((brand) => (
                <Pressable
                  key={brand}
                  onPress={() => router.push({ pathname: '/catalog', params: { q: brand } })}
                  style={({ pressed }) => [
                    styles.brandPill,
                    { backgroundColor: palette.surface, borderColor: palette.hairline },
                    pressed && styles.pressed,
                  ]}
                >
                  <Text style={[styles.brandPillText, { color: palette.text }]}>{brand}</Text>
                </Pressable>
              ))}
            </ScrollView>
          </View>
        ) : null}

        {showroom.length ? (
          <View style={styles.section}>
            <SectionHeading eyebrow="В ШОУРУМЕ" title="Можно посмотреть сегодня." />
            <CarRail cars={showroom} />
          </View>
        ) : null}

        {stock.length ? (
          <View style={styles.section}>
            <SectionHeading eyebrow="В НАЛИЧИИ" title="Без ожидания поставки." />
            <CarRail cars={stock} />
          </View>
        ) : null}

        {transit.length ? (
          <View style={styles.section}>
            <SectionHeading eyebrow="В ПУТИ" title="Следующее поступление." text="Автомобили, которые уже направляются в шоурум." />
            <CarRail cars={transit} />
          </View>
        ) : null}

        <View style={styles.section}>
          <SectionHeading eyebrow="ШОУРУМ" title="Пространство для спокойного выбора." />
          <ScrollView horizontal style={styles.horizontalRail} showsHorizontalScrollIndicator={false} contentContainerStyle={styles.showroomRail}>
            {SHOWROOM_IMAGES.map((image, index) => (
              <View key={image} style={[styles.showroomCard, { backgroundColor: palette.surface, borderColor: palette.hairline }]}> 
                <Image source={image} contentFit="cover" transition={180} style={styles.showroomImage} />
                <Text style={[styles.showroomTitle, { color: palette.text }]}>{['Коллекция вживую', 'Персональный просмотр', 'Auto Sale Umar · Tashkent'][index]}</Text>
              </View>
            ))}
          </ScrollView>
        </View>

        <View style={styles.section}>
          <View style={[styles.deliveryCard, { backgroundColor: dark ? '#151516' : '#111113' }]}> 
            <Text style={styles.deliveryEyebrow}>МЕЖДУНАРОДНАЯ ПОСТАВКА</Text>
            <Text style={styles.deliveryTitle}>Ищем автомобиль там, где он есть.</Text>
            <Text style={styles.deliveryText}>Подбор и поставка из ключевых автомобильных рынков с прозрачным статусом на каждом этапе.</Text>
            <View style={styles.marketWrap}>{MARKETS.map((market) => <View key={market} style={styles.marketPill}><Text style={styles.marketText}>{market}</Text></View>)}</View>
          </View>
        </View>

        <View style={styles.section}>
          <View style={[styles.requestCard, { backgroundColor: palette.surface, borderColor: palette.hairline }]}> 
            <Text style={[styles.eyebrow, { color: palette.secondary }]}>ПЕРСОНАЛЬНЫЙ ПОДБОР</Text>
            <Text style={[styles.requestTitle, { color: palette.text }]}>Не нашли нужный автомобиль?</Text>
            <Text style={[styles.sectionText, { color: palette.secondary }]}>Марка, модель, бюджет и срок покупки — команда Auto Sale Umar начнёт поиск под ваш запрос.</Text>
            <View style={styles.requestAction}>
              <AppleGlassButton
                prominent
                label="Найти автомобиль"
                symbol={{ ios: 'arrow.right', android: 'arrow_forward', web: 'arrow_forward' }}
                onPress={() => void Linking.openURL('https://autosaleumar.com/request-car/')}
              />
            </View>
          </View>
        </View>

        <View style={styles.footer}>
          <Image source={dark ? require('@/assets/wordmark-white.png') : require('@/assets/wordmark-black.png')} contentFit="contain" style={styles.footerLogo} />
          <Text style={[styles.footerText, { color: palette.secondary }]}>Премиальный автомобильный шоурум · Ташкент{`\n`}© 2026 Auto Sale Umar</Text>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { width: '100%', paddingHorizontal: 16, paddingTop: 4, paddingBottom: 112 },
  shell: { width: '100%', maxWidth: 720, alignSelf: 'center' },
  topbar: { minHeight: 62, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  wordmark: { width: 150, height: 30 },
  liveStatus: { minHeight: 32, paddingHorizontal: 11, borderRadius: 16, flexDirection: 'row', alignItems: 'center', gap: 7 },
  liveDot: { width: 7, height: 7, borderRadius: 4 },
  liveText: { fontSize: 12, fontWeight: '600' },
  heroCopy: { paddingTop: 30, paddingBottom: 24 },
  eyebrow: { fontSize: 11, fontWeight: '700', letterSpacing: 1.35 },
  heroTitle: { marginTop: 12, fontSize: 36, lineHeight: 38, fontWeight: '700', letterSpacing: -1.45 },
  heroText: { marginTop: 14, maxWidth: 560, fontSize: 17, lineHeight: 24, letterSpacing: -0.22 },
  loader: { paddingVertical: 24 },
  error: { paddingVertical: 16, fontSize: 15, lineHeight: 22 },
  featuredCard: { width: '100%', borderRadius: 30, overflow: 'hidden', borderWidth: StyleSheet.hairlineWidth },
  pressed: { transform: [{ scale: 0.985 }], opacity: 0.95 },
  featuredImageWrap: { width: '100%', aspectRatio: 1.38, position: 'relative' },
  statusPill: { position: 'absolute', left: 14, top: 14, minHeight: 31, paddingHorizontal: 11, borderRadius: 16, alignItems: 'center', justifyContent: 'center' },
  statusText: { fontSize: 12, fontWeight: '600' },
  featuredCopy: { padding: 18 },
  featuredBrand: { fontSize: 11, fontWeight: '700', letterSpacing: 0.85 },
  featuredModel: { marginTop: 5, fontSize: 27, lineHeight: 30, fontWeight: '700', letterSpacing: -0.85 },
  featuredPrice: { marginTop: 9, fontSize: 19, fontWeight: '600', letterSpacing: -0.35 },
  featuredAction: { marginTop: 17 },
  section: { width: '100%', paddingTop: 58 },
  sectionHeading: { marginBottom: 20 },
  sectionTitle: { marginTop: 8, fontSize: 28, lineHeight: 31, fontWeight: '700', letterSpacing: -0.95 },
  sectionText: { marginTop: 10, maxWidth: 580, fontSize: 16, lineHeight: 23, letterSpacing: -0.15 },
  horizontalRail: { width: '100%' },
  railContent: { gap: 12, paddingRight: 2 },
  brandRail: { gap: 8, paddingRight: 2 },
  brandPill: { minHeight: 46, paddingHorizontal: 16, borderRadius: 23, borderWidth: StyleSheet.hairlineWidth, alignItems: 'center', justifyContent: 'center' },
  brandPillText: { fontSize: 14, fontWeight: '600' },
  showroomRail: { gap: 12, paddingRight: 2 },
  showroomCard: { width: 286, maxWidth: '82%', borderRadius: 26, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden' },
  showroomImage: { width: '100%', aspectRatio: 1.25 },
  showroomTitle: { padding: 15, fontSize: 18, fontWeight: '600', letterSpacing: -0.35 },
  deliveryCard: { width: '100%', borderRadius: 30, padding: 22 },
  deliveryEyebrow: { color: 'rgba(255,255,255,0.56)', fontSize: 11, fontWeight: '700', letterSpacing: 1.25 },
  deliveryTitle: { marginTop: 9, color: '#FFFFFF', fontSize: 29, lineHeight: 32, fontWeight: '700', letterSpacing: -1 },
  deliveryText: { marginTop: 12, color: 'rgba(255,255,255,0.72)', fontSize: 16, lineHeight: 23 },
  marketWrap: { marginTop: 18, flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  marketPill: { minHeight: 34, paddingHorizontal: 11, borderRadius: 17, justifyContent: 'center', backgroundColor: 'rgba(255,255,255,0.10)', borderWidth: StyleSheet.hairlineWidth, borderColor: 'rgba(255,255,255,0.15)' },
  marketText: { color: '#FFFFFF', fontSize: 13, fontWeight: '500' },
  requestCard: { width: '100%', borderRadius: 30, padding: 22, borderWidth: StyleSheet.hairlineWidth },
  requestTitle: { marginTop: 8, fontSize: 28, lineHeight: 31, fontWeight: '700', letterSpacing: -0.95 },
  requestAction: { marginTop: 18 },
  footer: { paddingTop: 68, paddingBottom: 18, alignItems: 'flex-start' },
  footerLogo: { width: 146, height: 29 },
  footerText: { marginTop: 10, fontSize: 12, lineHeight: 18 },
});
