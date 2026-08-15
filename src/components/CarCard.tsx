import { Image } from 'expo-image';
import { router } from 'expo-router';
import { Pressable, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { absoluteMediaUrl } from '@/src/lib/api';
import { formatPrice, statusLabel } from '@/src/lib/format';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

type CarCardVariant = 'full' | 'rail';

export function CarCard({ car, hero = false, variant = 'full' }: { car: CatalogCar; hero?: boolean; variant?: CarCardVariant }) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const image = absoluteMediaUrl(car.coverUrl ?? car.variants?.[0]?.photos?.[0]?.url);
  const rail = variant === 'rail';

  return (
    <Pressable
      onPress={() => router.push({ pathname: '/car/[slug]', params: { slug: car.slug } })}
      style={({ pressed }) => [
        styles.card,
        rail && styles.railCard,
        { backgroundColor: palette.surface, borderColor: palette.hairline },
        pressed && styles.pressed,
      ]}
    >
      <View style={[styles.imageWrap, hero && styles.heroImageWrap, rail && styles.railImageWrap]}>
        {image ? (
          <Image source={image} contentFit="cover" transition={220} style={StyleSheet.absoluteFill} />
        ) : (
          <View style={[StyleSheet.absoluteFill, { backgroundColor: palette.background }]} />
        )}
        <View style={styles.status}>
          <Text style={styles.statusText}>{statusLabel(car.status)}</Text>
        </View>
      </View>
      <View style={[styles.copy, rail && styles.railCopy]}>
        <Text numberOfLines={1} style={[styles.brand, { color: palette.secondary }]}>{car.brand}</Text>
        <Text numberOfLines={2} style={[styles.model, rail && styles.railModel, { color: palette.text }]}>
          {car.model}{car.trim ? ` ${car.trim}` : ''}
        </Text>
        <Text style={[styles.price, rail && styles.railPrice, { color: palette.text }]}>{formatPrice(car)}</Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: 30,
    overflow: 'hidden',
    borderWidth: StyleSheet.hairlineWidth,
  },
  railCard: { width: 286, borderRadius: 32 },
  pressed: { transform: [{ scale: 0.985 }], opacity: 0.93 },
  imageWrap: { aspectRatio: 1.2, position: 'relative', backgroundColor: '#ECECEF' },
  heroImageWrap: { aspectRatio: 1.02 },
  railImageWrap: { aspectRatio: 1.28 },
  status: {
    position: 'absolute',
    left: 14,
    top: 14,
    borderRadius: 999,
    paddingHorizontal: 11,
    paddingVertical: 7,
    backgroundColor: 'rgba(17,17,17,0.72)',
  },
  statusText: { color: '#fff', fontSize: 12, fontWeight: '600' },
  copy: { padding: 18, gap: 4 },
  railCopy: { padding: 16 },
  brand: { fontSize: 12, fontWeight: '700', textTransform: 'uppercase', letterSpacing: 0.8 },
  model: { fontSize: 22, lineHeight: 25, fontWeight: '700', letterSpacing: -0.55 },
  railModel: { fontSize: 20, lineHeight: 23 },
  price: { fontSize: 18, fontWeight: '600', marginTop: 7 },
  railPrice: { fontSize: 16 },
});
