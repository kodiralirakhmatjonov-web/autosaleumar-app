import { Image } from 'expo-image';
import { router, useLocalSearchParams } from 'expo-router';
import { useEffect, useState } from 'react';
import { ActivityIndicator, Pressable, ScrollView, StyleSheet, Text, View, useColorScheme } from 'react-native';
import { GlassPill } from '@/src/components/GlassPill';
import { absoluteMediaUrl, getCar } from '@/src/lib/api';
import { formatPrice, statusLabel } from '@/src/lib/format';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

export default function CarScreen() {
  const { slug } = useLocalSearchParams<{ slug: string }>();
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const [car, setCar] = useState<CatalogCar | null>(null);
  const [error, setError] = useState(false);
  useEffect(() => { if (!slug) return; getCar(slug).then(setCar).catch(() => setError(true)); }, [slug]);
  if (!car && !error) return <View style={[styles.center, { backgroundColor: palette.background }]}><ActivityIndicator /></View>;
  if (!car) return <View style={[styles.center, { backgroundColor: palette.background }]}><Text style={{ color: palette.text }}>Автомобиль не найден.</Text></View>;
  const image = absoluteMediaUrl(car.coverUrl ?? car.variants?.[0]?.photos?.[0]?.url);
  return (
    <ScrollView style={{ backgroundColor: palette.background }} contentInsetAdjustmentBehavior="automatic" contentContainerStyle={styles.content}>
      <Pressable onPress={() => router.back()} style={styles.back}><GlassPill><Text style={[styles.backText, { color: palette.text }]}>‹ Назад</Text></GlassPill></Pressable>
      <View style={[styles.hero, { backgroundColor: palette.surface }]}>{image ? <Image source={image} contentFit="cover" style={StyleSheet.absoluteFill} /> : null}</View>
      <Text style={[styles.status, { color: palette.secondary }]}>{statusLabel(car.status).toUpperCase()}</Text>
      <Text style={[styles.title, { color: palette.text }]}>{car.brand} {car.model}</Text>
      {car.trim ? <Text style={[styles.trim, { color: palette.secondary }]}>{car.trim}{car.year ? ` · ${car.year}` : ''}</Text> : null}
      <Text style={[styles.price, { color: palette.text }]}>{formatPrice(car)}</Text>
      <Text style={[styles.description, { color: palette.secondary }]}>{car.shortDescriptionRu || car.engineText || 'Подробная информация об автомобиле будет добавлена.'}</Text>
      <View style={{ height: 90 }} />
    </ScrollView>
  );
}
const styles = StyleSheet.create({ center: { flex: 1, alignItems: 'center', justifyContent: 'center' }, content: { padding: 18, gap: 10 }, back: { alignSelf: 'flex-start', marginTop: 8, marginBottom: 8 }, backText: { fontWeight: '600', fontSize: 16 }, hero: { aspectRatio: 1.03, borderRadius: 32, overflow: 'hidden' }, status: { fontSize: 12, fontWeight: '700', letterSpacing: 1.1, marginTop: 14 }, title: { fontSize: 36, lineHeight: 40, fontWeight: '700', letterSpacing: -1.2 }, trim: { fontSize: 17 }, price: { fontSize: 28, fontWeight: '700', marginTop: 10 }, description: { fontSize: 17, lineHeight: 25, marginTop: 12 } });
