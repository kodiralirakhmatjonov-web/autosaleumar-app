import { Image } from 'expo-image';
import { router } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { Pressable, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { AdaptiveGlass } from '@/src/components/AdaptiveGlass';
import { absoluteMediaUrl } from '@/src/lib/api';
import { formatPrice, statusLabel } from '@/src/lib/format';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

export function CarCard({ car, variant = 'full' }: { car: CatalogCar; variant?: 'full' | 'rail' }) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const image = absoluteMediaUrl(car.coverUrl ?? car.variants?.[0]?.photos?.[0]?.url);
  const rail = variant === 'rail';

  const open = () => router.push({ pathname: '/car/[slug]', params: { slug: car.slug } });

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`Открыть ${car.brand} ${car.model}`}
      onPress={open}
      style={({ pressed }) => [rail ? styles.railCard : styles.fullCard, pressed && styles.pressed]}
    >
      <View
        style={[
          styles.imageWrap,
          rail ? styles.railImage : styles.fullImage,
          { backgroundColor: palette.surface, borderColor: palette.hairline },
        ]}
      >
        {image ? <Image source={image} contentFit="contain" transition={160} style={StyleSheet.absoluteFill} /> : null}

        <AdaptiveGlass style={styles.statusPill}>
          <View style={styles.statusContent}>
            <View style={[styles.statusDot, { backgroundColor: car.status === 'in_transit' ? '#FF9F0A' : '#30D158' }]} />
            <Text style={[styles.statusText, { color: palette.text }]}>{statusLabel(car.status)}</Text>
          </View>
        </AdaptiveGlass>

        {car.isNewArrival ? (
          <AdaptiveGlass dark style={styles.newPill}>
            <Text style={styles.newText}>NEW</Text>
          </AdaptiveGlass>
        ) : null}
      </View>

      <View style={rail ? styles.railCopy : styles.fullCopy}>
        <View style={styles.eyebrowRow}>
          <Text numberOfLines={1} style={[styles.brand, { color: palette.secondary }]}>{car.brand.toUpperCase()}</Text>
          {car.year ? <Text style={[styles.year, { color: palette.tertiary }]}>{car.year}</Text> : null}
        </View>

        <Text numberOfLines={1} style={[rail ? styles.railModel : styles.fullModel, { color: palette.text }]}>{car.model}</Text>
        {car.trim ? <Text numberOfLines={1} style={[styles.trim, { color: palette.secondary }]}>{car.trim}</Text> : null}

        {!rail ? (
          <View style={styles.specLine}>
            {car.horsepowerHp ? <Text style={[styles.spec, { color: palette.secondary }]}>{car.horsepowerHp} л.с.</Text> : null}
            {car.driveType ? <Text style={[styles.spec, { color: palette.secondary }]}>{car.driveType}</Text> : null}
            {car.mileageKm != null ? <Text style={[styles.spec, { color: palette.secondary }]}>{new Intl.NumberFormat('ru-RU').format(car.mileageKm)} км</Text> : null}
          </View>
        ) : null}

        <View style={styles.bottomRow}>
          <Text numberOfLines={1} style={[styles.price, { color: palette.text }]}>{formatPrice(car)}</Text>
          <AdaptiveGlass interactive style={styles.disclosure}>
            <SymbolView
              name={{ ios: 'arrow.up.right', android: 'north_east', web: 'north_east' }}
              size={13}
              tintColor={palette.text}
              weight="semibold"
            />
          </AdaptiveGlass>
        </View>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  pressed: { opacity: 0.82, transform: [{ scale: 0.992 }] },
  railCard: { width: 286 },
  fullCard: { width: '100%', marginBottom: 30 },
  imageWrap: { width: '100%', borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden' },
  railImage: { aspectRatio: 1.24, borderRadius: 30 },
  fullImage: { aspectRatio: 1.42, borderRadius: 32 },
  statusPill: { position: 'absolute', top: 12, left: 12, minHeight: 34, borderRadius: 17, paddingHorizontal: 12, justifyContent: 'center' },
  statusContent: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  statusDot: { width: 7, height: 7, borderRadius: 4 },
  statusText: { fontSize: 12, lineHeight: 15, fontWeight: '600', letterSpacing: -0.1 },
  newPill: { position: 'absolute', top: 12, right: 12, minHeight: 34, borderRadius: 17, paddingHorizontal: 11, justifyContent: 'center' },
  newText: { color: '#FFFFFF', fontSize: 10, lineHeight: 13, fontWeight: '700', letterSpacing: 0.9 },
  railCopy: { paddingTop: 13, paddingHorizontal: 2 },
  fullCopy: { paddingTop: 14, paddingHorizontal: 3 },
  eyebrowRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  brand: { flex: 1, fontSize: 10, lineHeight: 13, fontWeight: '700', letterSpacing: 0.9 },
  year: { fontSize: 12, lineHeight: 15, fontWeight: '500' },
  railModel: { marginTop: 3, fontSize: 21, lineHeight: 25, fontWeight: '700', letterSpacing: -0.55 },
  fullModel: { marginTop: 3, fontSize: 25, lineHeight: 29, fontWeight: '700', letterSpacing: -0.75 },
  trim: { marginTop: 3, fontSize: 13, lineHeight: 18 },
  specLine: { marginTop: 9, flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: 7 },
  spec: { fontSize: 12, lineHeight: 16 },
  bottomRow: { marginTop: 13, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  price: { flex: 1, fontSize: 17, lineHeight: 21, fontWeight: '700', letterSpacing: -0.28 },
  disclosure: { width: 34, height: 34, borderRadius: 17, alignItems: 'center', justifyContent: 'center' },
});
