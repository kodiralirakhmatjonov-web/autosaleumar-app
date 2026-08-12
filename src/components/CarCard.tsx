import { Image } from 'expo-image';
import { router } from 'expo-router';
import { Pressable, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { absoluteMediaUrl } from '@/src/lib/api';
import { formatPrice, statusLabel } from '@/src/lib/format';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

export function CarCard({ car, hero = false }: { car: CatalogCar; hero?: boolean }) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const image = absoluteMediaUrl(car.coverUrl ?? car.variants?.[0]?.photos?.[0]?.url);
  return (
    <Pressable onPress={() => router.push({ pathname: '/car/[slug]', params: { slug: car.slug } })} style={({ pressed }) => [styles.card, { backgroundColor: palette.surface }, pressed && styles.pressed]}>
      <View style={[styles.imageWrap, hero && styles.heroImageWrap]}>
        {image ? <Image source={image} contentFit="cover" transition={250} style={StyleSheet.absoluteFill} /> : <View style={[StyleSheet.absoluteFill, { backgroundColor: palette.background }]} />}
        <View style={styles.status}><Text style={styles.statusText}>{statusLabel(car.status)}</Text></View>
      </View>
      <View style={styles.copy}>
        <Text numberOfLines={1} style={[styles.brand, { color: palette.secondary }]}>{car.brand}</Text>
        <Text numberOfLines={2} style={[styles.model, { color: palette.text }]}>{car.model}{car.trim ? ` ${car.trim}` : ''}</Text>
        <Text style={[styles.price, { color: palette.text }]}>{formatPrice(car)}</Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: { borderRadius: 30, overflow: 'hidden' },
  pressed: { transform: [{ scale: 0.985 }] },
  imageWrap: { aspectRatio: 1.2, position: 'relative', backgroundColor: '#ECECEF' },
  heroImageWrap: { aspectRatio: 1.02 },
  status: { position: 'absolute', left: 14, top: 14, borderRadius: 999, paddingHorizontal: 11, paddingVertical: 7, backgroundColor: 'rgba(17,17,17,0.72)' },
  statusText: { color: '#fff', fontSize: 12, fontWeight: '600' },
  copy: { padding: 18, gap: 4 },
  brand: { fontSize: 13, fontWeight: '600', textTransform: 'uppercase', letterSpacing: 0.7 },
  model: { fontSize: 22, fontWeight: '700', letterSpacing: -0.5 },
  price: { fontSize: 18, fontWeight: '600', marginTop: 7 },
});
