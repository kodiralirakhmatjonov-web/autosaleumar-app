import { Image } from 'expo-image';
import { router, Stack, useLocalSearchParams } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Linking,
  Platform,
  Pressable,
  ScrollView,
  Share,
  StyleSheet,
  Text,
  View,
  useColorScheme,
  useWindowDimensions,
} from 'react-native';
import { AdaptiveGlass } from '@/src/components/AdaptiveGlass';
import { absoluteMediaUrl, getCar } from '@/src/lib/api';
import { formatPrice, statusLabel } from '@/src/lib/format';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

function uniquePhotos(car: CatalogCar): string[] {
  const values: Array<string | null | undefined> = [car.coverUrl];
  car.variants?.forEach((variant) => {
    variant.photos?.forEach((photo) => values.push(photo.url));
    variant.interiorPhotos?.forEach((photo) => values.push(photo.url));
    variant.detailPhotos?.forEach((photo) => values.push(photo.url));
  });

  return Array.from(new Set(values.map(absoluteMediaUrl).filter((value): value is string => Boolean(value)))).slice(0, 14);
}

function SpecTile({ label, value, symbol }: { label: string; value: string; symbol: 'calendar' | 'bolt.fill' | 'arrow.triangle.2.circlepath' | 'road.lanes' | 'gearshape.2.fill' | 'gearshape.fill' }) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const android = symbol === 'calendar' ? 'calendar_month' : symbol === 'arrow.triangle.2.circlepath' ? 'settings' : symbol === 'road.lanes' ? 'route' : symbol === 'gearshape.2.fill' ? 'speed' : symbol === 'gearshape.fill' ? 'settings' : 'speed';
  return (
    <View style={[styles.specTile, { backgroundColor: palette.surface, borderColor: palette.hairline }]}>
      <View style={[styles.specIcon, { backgroundColor: palette.fill }]}>
        <SymbolView name={{ ios: symbol, android, web: android }} size={17} tintColor={palette.text} weight="semibold" />
      </View>
      <Text style={[styles.specValue, { color: palette.text }]} numberOfLines={2}>{value}</Text>
      <Text style={[styles.specLabel, { color: palette.secondary }]}>{label}</Text>
    </View>
  );
}

export default function CarScreen() {
  const { slug } = useLocalSearchParams<{ slug: string }>();
  const dark = useColorScheme() === 'dark';
  const palette = colors[dark ? 'dark' : 'light'];
  const { width } = useWindowDimensions();
  const [car, setCar] = useState<CatalogCar | null>(null);
  const [error, setError] = useState(false);
  const [saved, setSaved] = useState(false);
  const [galleryIndex, setGalleryIndex] = useState(0);

  useEffect(() => {
    if (!slug) return;
    getCar(slug).then(setCar).catch(() => setError(true));
  }, [slug]);

  const photos = useMemo(() => car ? uniquePhotos(car) : [], [car]);
  const galleryWidth = Math.max(280, Math.min(width, 720) - 24);

  const shareCar = async () => {
    if (!car) return;
    await Share.share({ message: `${car.brand} ${car.model} — ${formatPrice(car)} · Auto Sale Umar` });
  };

  const requestCar = () => {
    if (!car) return;
    void Linking.openURL(`https://autosaleumar.com/request-car/?car=${encodeURIComponent(car.slug)}`);
  };

  if (!car && !error) {
    return <View style={[styles.center, { backgroundColor: palette.background }]}><ActivityIndicator /></View>;
  }

  if (!car) {
    return <View style={[styles.center, { backgroundColor: palette.background }]}><Text style={{ color: palette.text }}>Автомобиль не найден.</Text></View>;
  }

  const specTiles = [
    car.year ? { label: 'Год', value: String(car.year), symbol: 'calendar' as const } : null,
    car.horsepowerHp ? { label: 'Мощность', value: `${car.horsepowerHp} л.с.`, symbol: 'bolt.fill' as const } : null,
    car.driveType ? { label: 'Привод', value: car.driveType, symbol: 'arrow.triangle.2.circlepath' as const } : null,
    car.mileageKm != null ? { label: 'Пробег', value: `${new Intl.NumberFormat('ru-RU').format(car.mileageKm)} км`, symbol: 'road.lanes' as const } : null,
    car.engineText ? { label: 'Двигатель', value: car.engineText, symbol: 'gearshape.2.fill' as const } : null,
    car.transmission ? { label: 'Коробка', value: car.transmission, symbol: 'gearshape.fill' as const } : null,
  ].filter((item): item is NonNullable<typeof item> => Boolean(item));

  const performance = [
    car.horsepowerHp ? { value: String(car.horsepowerHp), unit: 'л.с.', label: 'мощность' } : null,
    car.acceleration0100 ? { value: String(car.acceleration0100), unit: 'с', label: '0–100 км/ч' } : null,
    car.topSpeedKmh ? { value: String(car.topSpeedKmh), unit: 'км/ч', label: 'макс. скорость' } : null,
  ].filter((item): item is NonNullable<typeof item> => Boolean(item));

  return (
    <>
      <Stack.Screen options={{ headerTitle: '' }} />

      {process.env.EXPO_OS === 'ios' ? (
        <>
          <Stack.Toolbar placement="right">
            <Stack.Toolbar.Button icon={saved ? 'heart.fill' : 'heart'} onPress={() => setSaved((value) => !value)} />
            <Stack.Toolbar.Button icon="square.and.arrow.up" onPress={() => void shareCar()} />
          </Stack.Toolbar>
          <Stack.Toolbar>
            <Stack.Toolbar.Spacer />
            <Stack.Toolbar.Button icon="paperplane.fill" onPress={requestCar}>Запросить</Stack.Toolbar.Button>
            <Stack.Toolbar.Spacer />
          </Stack.Toolbar>
        </>
      ) : null}

      <ScrollView
        style={{ backgroundColor: palette.background }}
        contentInsetAdjustmentBehavior="automatic"
        contentContainerStyle={styles.content}
      >
        <View style={styles.shell}>
          <View style={[styles.gallery, { width: galleryWidth, backgroundColor: palette.surface, borderColor: palette.hairline }]}>
            <ScrollView
              horizontal
              pagingEnabled
              showsHorizontalScrollIndicator={false}
              onMomentumScrollEnd={(event) => setGalleryIndex(Math.round(event.nativeEvent.contentOffset.x / galleryWidth))}
            >
              {(photos.length ? photos : [null]).map((photo, index) => (
                <View key={photo ?? `empty-${index}`} style={{ width: galleryWidth, height: '100%' }}>
                  {photo ? <Image source={photo} contentFit="contain" transition={180} style={StyleSheet.absoluteFill} /> : null}
                </View>
              ))}
            </ScrollView>

            {Platform.OS === 'web' ? (
              <View style={styles.webToolbar}>
                <AdaptiveGlass interactive style={styles.webToolButton}>
                  <Pressable onPress={() => router.back()} style={styles.webToolPressable}>
                    <SymbolView name={{ ios: 'chevron.left', android: 'arrow_back_ios_new', web: 'arrow_back_ios_new' }} size={16} tintColor={palette.text} weight="semibold" />
                  </Pressable>
                </AdaptiveGlass>
                <View style={styles.webToolbarRight}>
                  <AdaptiveGlass interactive style={styles.webToolButton}>
                    <Pressable onPress={() => setSaved((value) => !value)} style={styles.webToolPressable}>
                      <SymbolView name={{ ios: saved ? 'heart.fill' : 'heart', android: 'favorite', web: 'favorite' }} size={17} tintColor={palette.text} />
                    </Pressable>
                  </AdaptiveGlass>
                  <AdaptiveGlass interactive style={styles.webToolButton}>
                    <Pressable onPress={() => void shareCar()} style={styles.webToolPressable}>
                      <SymbolView name={{ ios: 'square.and.arrow.up', android: 'ios_share', web: 'ios_share' }} size={17} tintColor={palette.text} />
                    </Pressable>
                  </AdaptiveGlass>
                </View>
              </View>
            ) : null}

            <AdaptiveGlass style={styles.galleryStatus}>
              <View style={styles.galleryStatusInner}>
                <View style={[styles.statusDot, { backgroundColor: car.status === 'in_transit' ? '#FF9F0A' : '#30D158' }]} />
                <Text style={[styles.galleryStatusText, { color: palette.text }]}>{statusLabel(car.status)}</Text>
              </View>
            </AdaptiveGlass>

            {photos.length > 1 ? (
              <AdaptiveGlass dark style={styles.galleryCounter}>
                <Text style={styles.galleryCounterText}>{galleryIndex + 1} / {photos.length}</Text>
              </AdaptiveGlass>
            ) : null}
          </View>

          {photos.length > 1 ? (
            <View style={styles.dots}>
              {photos.slice(0, 8).map((photo, index) => (
                <View key={photo} style={[styles.dot, { backgroundColor: index === galleryIndex ? palette.text : palette.hairline }]} />
              ))}
            </View>
          ) : null}

          <View style={styles.identity}>
            <View style={styles.identityEyebrowRow}>
              <Text style={[styles.brand, { color: palette.secondary }]}>{car.brand.toUpperCase()}</Text>
              {car.isNewArrival ? <Text style={[styles.newArrival, { color: palette.accent }]}>НОВОЕ ПОСТУПЛЕНИЕ</Text> : null}
            </View>
            <Text style={[styles.title, { color: palette.text }]}>{car.model}</Text>
            {car.trim ? <Text style={[styles.trim, { color: palette.secondary }]}>{car.trim}</Text> : null}
            <View style={styles.priceRow}>
              <Text style={[styles.price, { color: palette.text }]}>{formatPrice(car)}</Text>
              {car.year ? <Text style={[styles.year, { color: palette.secondary }]}>{car.year}</Text> : null}
            </View>
          </View>

          {specTiles.length ? (
            <View style={styles.section}>
              <Text style={[styles.sectionKicker, { color: palette.secondary }]}>OVERVIEW</Text>
              <Text style={[styles.sectionTitle, { color: palette.text }]}>Главное</Text>
              <View style={styles.specGrid}>
                {specTiles.slice(0, 6).map((spec) => <SpecTile key={spec.label} {...spec} />)}
              </View>
            </View>
          ) : null}

          {performance.length >= 2 ? (
            <View style={styles.section}>
              <View style={styles.performanceCard}>
                <Text style={styles.performanceKicker}>PERFORMANCE</Text>
                <Text style={styles.performanceTitle}>Характер в цифрах.</Text>
                <View style={styles.performanceGrid}>
                  {performance.map((item) => (
                    <View key={item.label} style={styles.performanceItem}>
                      <View style={styles.performanceValueRow}>
                        <Text style={styles.performanceValue}>{item.value}</Text>
                        <Text style={styles.performanceUnit}>{item.unit}</Text>
                      </View>
                      <Text style={styles.performanceLabel}>{item.label}</Text>
                    </View>
                  ))}
                </View>
              </View>
            </View>
          ) : null}

          {car.variants?.length ? (
            <View style={styles.section}>
              <Text style={[styles.sectionKicker, { color: palette.secondary }]}>CONFIGURATION</Text>
              <Text style={[styles.sectionTitle, { color: palette.text }]}>Варианты</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.variantRail}>
                {car.variants.map((variant) => (
                  <AdaptiveGlass key={variant.id} style={styles.variantCard}>
                    <View style={[styles.swatch, { backgroundColor: variant.exteriorSwatch || '#D1D1D6', borderColor: palette.hairline }]} />
                    <View style={styles.variantCopy}>
                      <Text numberOfLines={1} style={[styles.variantName, { color: palette.text }]}>{variant.exteriorColorName || 'Экстерьер'}</Text>
                      <Text numberOfLines={1} style={[styles.variantInterior, { color: palette.secondary }]}>{variant.interiorColorName || 'Интерьер'}</Text>
                    </View>
                  </AdaptiveGlass>
                ))}
              </ScrollView>
            </View>
          ) : null}

          <View style={styles.section}>
            <Text style={[styles.sectionKicker, { color: palette.secondary }]}>DETAILS</Text>
            <Text style={[styles.sectionTitle, { color: palette.text }]}>Об автомобиле</Text>
            <Text style={[styles.description, { color: palette.secondary }]}>{car.descriptionRu || car.shortDescriptionRu || 'Подробная информация об автомобиле будет добавлена.'}</Text>
          </View>

          {car.instagramUrl ? (
            <Pressable onPress={() => void Linking.openURL(car.instagramUrl!)} style={({ pressed }) => [styles.instagramCard, { backgroundColor: palette.surface, borderColor: palette.hairline }, pressed && styles.pressed]}>
              <View style={[styles.instagramIcon, { backgroundColor: palette.fill }]}>
                <SymbolView name={{ ios: 'play.rectangle.fill', android: 'smart_display', web: 'smart_display' }} size={20} tintColor={palette.text} />
              </View>
              <View style={styles.instagramCopy}>
                <Text style={[styles.instagramTitle, { color: palette.text }]}>Посмотреть обзор</Text>
                <Text style={[styles.instagramText, { color: palette.secondary }]}>Видео Auto Sale Umar</Text>
              </View>
              <SymbolView name={{ ios: 'arrow.up.right', android: 'north_east', web: 'north_east' }} size={15} tintColor={palette.secondary} />
            </Pressable>
          ) : null}
        </View>
      </ScrollView>

      {Platform.OS !== 'ios' ? (
        <AdaptiveGlass style={styles.webBottomBar}>
          <View style={styles.webBottomInner}>
            <View style={styles.webBottomPriceCopy}>
              <Text style={[styles.webBottomLabel, { color: palette.secondary }]}>Стоимость</Text>
              <Text numberOfLines={1} style={[styles.webBottomPrice, { color: palette.text }]}>{formatPrice(car)}</Text>
            </View>
            <Pressable onPress={requestCar} style={({ pressed }) => [styles.requestButton, pressed && styles.pressed]}>
              <Text style={styles.requestButtonText}>Запросить</Text>
              <SymbolView name={{ ios: 'arrow.right', android: 'arrow_forward', web: 'arrow_forward' }} size={16} tintColor="#FFFFFF" weight="semibold" />
            </Pressable>
          </View>
        </AdaptiveGlass>
      ) : null}
    </>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  content: { width: '100%', paddingHorizontal: 12, paddingTop: 8, paddingBottom: 168 },
  shell: { width: '100%', maxWidth: 720, alignSelf: 'center' },
  pressed: { opacity: 0.82, transform: [{ scale: 0.992 }] },
  gallery: { alignSelf: 'center', aspectRatio: 1.16, borderRadius: 36, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden' },
  webToolbar: { position: 'absolute', top: 14, left: 14, right: 14, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  webToolbarRight: { flexDirection: 'row', gap: 8 },
  webToolButton: { width: 42, height: 42, borderRadius: 21 },
  webToolPressable: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  galleryStatus: { position: 'absolute', left: 14, bottom: 14, minHeight: 36, borderRadius: 18, paddingHorizontal: 13, justifyContent: 'center' },
  galleryStatusInner: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  statusDot: { width: 7, height: 7, borderRadius: 4 },
  galleryStatusText: { fontSize: 12, lineHeight: 15, fontWeight: '600' },
  galleryCounter: { position: 'absolute', right: 14, bottom: 14, minHeight: 34, borderRadius: 17, paddingHorizontal: 12, justifyContent: 'center' },
  galleryCounterText: { color: '#FFFFFF', fontSize: 11, lineHeight: 14, fontWeight: '600' },
  dots: { minHeight: 28, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 5 },
  dot: { width: 5, height: 5, borderRadius: 3 },
  identity: { paddingHorizontal: 6, paddingTop: 22 },
  identityEyebrowRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  brand: { flex: 1, fontSize: 10, lineHeight: 13, fontWeight: '700', letterSpacing: 1.15 },
  newArrival: { fontSize: 9, lineHeight: 12, fontWeight: '700', letterSpacing: 0.9 },
  title: { marginTop: 7, fontSize: 39, lineHeight: 42, fontWeight: '700', letterSpacing: -1.55 },
  trim: { marginTop: 7, fontSize: 16, lineHeight: 22 },
  priceRow: { marginTop: 19, flexDirection: 'row', alignItems: 'baseline', justifyContent: 'space-between', gap: 14 },
  price: { flex: 1, fontSize: 25, lineHeight: 30, fontWeight: '700', letterSpacing: -0.6 },
  year: { fontSize: 15, lineHeight: 20, fontWeight: '500' },
  section: { paddingHorizontal: 6, paddingTop: 48 },
  sectionKicker: { fontSize: 9, lineHeight: 12, fontWeight: '700', letterSpacing: 1.5 },
  sectionTitle: { marginTop: 5, fontSize: 29, lineHeight: 33, fontWeight: '700', letterSpacing: -0.9 },
  specGrid: { marginTop: 18, flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  specTile: { width: '48.4%', minHeight: 132, borderRadius: 26, borderWidth: StyleSheet.hairlineWidth, padding: 14 },
  specIcon: { width: 34, height: 34, borderRadius: 17, alignItems: 'center', justifyContent: 'center' },
  specValue: { marginTop: 17, fontSize: 17, lineHeight: 21, fontWeight: '700', letterSpacing: -0.3 },
  specLabel: { marginTop: 4, fontSize: 11, lineHeight: 15 },
  performanceCard: { minHeight: 252, borderRadius: 34, backgroundColor: '#111113', padding: 22 },
  performanceKicker: { color: 'rgba(255,255,255,0.52)', fontSize: 9, lineHeight: 12, fontWeight: '700', letterSpacing: 1.55 },
  performanceTitle: { marginTop: 6, color: '#FFFFFF', fontSize: 27, lineHeight: 31, fontWeight: '700', letterSpacing: -0.75 },
  performanceGrid: { marginTop: 36, flexDirection: 'row', gap: 12 },
  performanceItem: { flex: 1 },
  performanceValueRow: { flexDirection: 'row', alignItems: 'baseline', gap: 3 },
  performanceValue: { color: '#FFFFFF', fontSize: 28, lineHeight: 31, fontWeight: '700', letterSpacing: -0.8 },
  performanceUnit: { color: 'rgba(255,255,255,0.66)', fontSize: 11, lineHeight: 15, fontWeight: '600' },
  performanceLabel: { marginTop: 5, color: 'rgba(255,255,255,0.52)', fontSize: 10, lineHeight: 14 },
  variantRail: { paddingTop: 18, paddingRight: 16, gap: 10 },
  variantCard: { width: 210, minHeight: 78, borderRadius: 24, padding: 12, flexDirection: 'row', alignItems: 'center', gap: 12 },
  swatch: { width: 46, height: 46, borderRadius: 23, borderWidth: StyleSheet.hairlineWidth },
  variantCopy: { flex: 1 },
  variantName: { fontSize: 13, lineHeight: 17, fontWeight: '600' },
  variantInterior: { marginTop: 3, fontSize: 11, lineHeight: 15 },
  description: { marginTop: 14, maxWidth: 620, fontSize: 16, lineHeight: 25, letterSpacing: -0.08 },
  instagramCard: { marginHorizontal: 6, marginTop: 38, minHeight: 76, borderRadius: 26, borderWidth: StyleSheet.hairlineWidth, paddingHorizontal: 14, flexDirection: 'row', alignItems: 'center', gap: 12 },
  instagramIcon: { width: 42, height: 42, borderRadius: 21, alignItems: 'center', justifyContent: 'center' },
  instagramCopy: { flex: 1 },
  instagramTitle: { fontSize: 15, lineHeight: 19, fontWeight: '600' },
  instagramText: { marginTop: 2, fontSize: 12, lineHeight: 16 },
  webBottomBar: { position: 'absolute', left: 14, right: 14, bottom: 12, minHeight: 76, borderRadius: 32, paddingHorizontal: 12, paddingVertical: 10 },
  webBottomInner: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: 12 },
  webBottomPriceCopy: { flex: 1, paddingLeft: 5 },
  webBottomLabel: { fontSize: 10, lineHeight: 13, fontWeight: '500' },
  webBottomPrice: { marginTop: 2, fontSize: 16, lineHeight: 20, fontWeight: '700', letterSpacing: -0.25 },
  requestButton: { minHeight: 52, borderRadius: 26, backgroundColor: '#111113', paddingHorizontal: 20, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8 },
  requestButtonText: { color: '#FFFFFF', fontSize: 14, lineHeight: 18, fontWeight: '600' },
});
