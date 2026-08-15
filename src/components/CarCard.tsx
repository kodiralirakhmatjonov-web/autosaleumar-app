import { Image } from 'expo-image';
import { router } from 'expo-router';
import { Pressable, StyleSheet, Text, View, useColorScheme, useWindowDimensions } from 'react-native';
import { absoluteMediaUrl } from '@/src/lib/api';
import { formatPrice, statusLabel } from '@/src/lib/format';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

type CarCardVariant = 'full' | 'rail';

export function CarCard({ car, variant = 'full' }: { car: CatalogCar; variant?: CarCardVariant }) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const { width } = useWindowDimensions();
  const image = absoluteMediaUrl(car.coverUrl ?? car.variants?.[0]?.photos?.[0]?.url);
  const rail = variant === 'rail';
  const railWidth = Math.min(Math.max(width * 0.78, 258), 310);

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${car.brand} ${car.model}`}
      onPress={() => router.push({ pathname: '/car/[slug]', params: { slug: car.slug } })}
      style={({ pressed }) => [
        styles.card,
        rail && { width: railWidth },
        { backgroundColor: palette.surface, borderColor: palette.hairline },
        pressed && styles.pressed,
      ]}
    >
      <View style={[styles.imageWrap, { backgroundColor: palette.elevated }]}> 
        {image ? <Image source={image} contentFit="contain" transition={180} style={StyleSheet.absoluteFill} /> : null}
        <View style={styles.status}>
          <Text style={styles.statusText}>{statusLabel(car.status)}</Text>
        </View>
      </View>

      <View style={styles.copy}>
        <Text numberOfLines={1} style={[styles.brand, { color: palette.secondary }]}>{car.brand.toUpperCase()}</Text>
        <Text numberOfLines={1} style={[styles.model, { color: palette.text }]}>{car.model}</Text>
        {car.trim ? <Text numberOfLines={1} style={[styles.trim, { color: palette.secondary }]}>{car.trim}</Text> : null}
        <View style={styles.metaRow}>
          <Text numberOfLines={1} style={[styles.price, { color: palette.text }]}>{formatPrice(car)}</Text>
          {car.year ? <Text style={[styles.year, { color: palette.secondary }]}>{car.year}</Text> : null}
        </View>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: { width: '100%', borderRadius: 26, overflow: 'hidden', borderWidth: StyleSheet.hairlineWidth },
  pressed: { transform: [{ scale: 0.985 }], opacity: 0.93 },
  imageWrap: { aspectRatio: 1.48, position: 'relative' },
  status: { position: 'absolute', left: 12, top: 12, minHeight: 28, borderRadius: 14, paddingHorizontal: 10, alignItems: 'center', justifyContent: 'center', backgroundColor: 'rgba(0,0,0,0.66)' },
  statusText: { color: '#FFFFFF', fontSize: 11, lineHeight: 14, fontWeight: '600' },
  copy: { paddingHorizontal: 15, paddingTop: 14, paddingBottom: 15 },
  brand: { fontSize: 10, lineHeight: 13, fontWeight: '700', letterSpacing: 0.75 },
  model: { marginTop: 3, fontSize: 20, lineHeight: 24, fontWeight: '700', letterSpacing: -0.5 },
  trim: { marginTop: 1, fontSize: 14, lineHeight: 19 },
  metaRow: { marginTop: 10, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  price: { flex: 1, fontSize: 16, lineHeight: 20, fontWeight: '600', letterSpacing: -0.2 },
  year: { fontSize: 13, lineHeight: 18, fontWeight: '500' },
});
