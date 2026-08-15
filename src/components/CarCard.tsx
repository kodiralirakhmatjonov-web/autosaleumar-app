import { Image } from 'expo-image';
import { router } from 'expo-router';
import { Pressable, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { absoluteMediaUrl } from '@/src/lib/api';
import { formatPrice, statusLabel } from '@/src/lib/format';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

type CarCardVariant = 'full' | 'rail';

export function CarCard({ car, variant = 'full' }: { car: CatalogCar; variant?: CarCardVariant }) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const image = absoluteMediaUrl(car.coverUrl ?? car.variants?.[0]?.photos?.[0]?.url);
  const rail = variant === 'rail';

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${car.brand} ${car.model}`}
      onPress={() => router.push({ pathname: '/car/[slug]', params: { slug: car.slug } })}
      style={({ pressed }) => [
        styles.card,
        rail && styles.railCard,
        { backgroundColor: palette.surface, borderColor: palette.hairline },
        pressed && styles.pressed,
      ]}
    >
      <View style={[styles.imageWrap, { backgroundColor: palette.elevated }]}> 
        {image ? (
          <Image source={image} contentFit="contain" transition={180} style={StyleSheet.absoluteFill} />
        ) : null}
        <View style={[styles.status, { backgroundColor: palette.fill }]}>
          <Text style={[styles.statusText, { color: palette.text }]}>{statusLabel(car.status)}</Text>
        </View>
      </View>

      <View style={styles.copy}>
        <Text numberOfLines={1} style={[styles.brand, { color: palette.secondary }]}>{car.brand.toUpperCase()}</Text>
        <Text numberOfLines={2} style={[styles.model, rail && styles.railModel, { color: palette.text }]}> 
          {car.model}{car.trim ? ` ${car.trim}` : ''}
        </Text>
        <View style={styles.metaRow}>
          <Text numberOfLines={1} style={[styles.price, { color: palette.text }]}>{formatPrice(car)}</Text>
          {car.year ? <Text style={[styles.year, { color: palette.secondary }]}>{car.year}</Text> : null}
        </View>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    width: '100%',
    borderRadius: 26,
    overflow: 'hidden',
    borderWidth: StyleSheet.hairlineWidth,
  },
  railCard: { width: 292, maxWidth: '82%' },
  pressed: { transform: [{ scale: 0.985 }], opacity: 0.94 },
  imageWrap: { aspectRatio: 1.46, position: 'relative' },
  status: {
    position: 'absolute',
    left: 12,
    top: 12,
    minHeight: 30,
    borderRadius: 15,
    paddingHorizontal: 11,
    alignItems: 'center',
    justifyContent: 'center',
  },
  statusText: { fontSize: 12, fontWeight: '600', letterSpacing: -0.1 },
  copy: { padding: 16, gap: 4 },
  brand: { fontSize: 11, fontWeight: '700', letterSpacing: 0.75 },
  model: { fontSize: 21, lineHeight: 24, fontWeight: '700', letterSpacing: -0.55 },
  railModel: { fontSize: 20, lineHeight: 23 },
  metaRow: { marginTop: 8, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  price: { flex: 1, fontSize: 16, fontWeight: '600', letterSpacing: -0.2 },
  year: { fontSize: 14, fontWeight: '500' },
});
