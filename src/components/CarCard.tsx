import { GlassView, isGlassEffectAPIAvailable } from 'expo-glass-effect';
import { Image } from 'expo-image';
import { router } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { Platform, Pressable, StyleSheet, Text, View, useColorScheme, useWindowDimensions } from 'react-native';
import { absoluteMediaUrl } from '@/src/lib/api';
import { formatPrice, statusLabel } from '@/src/lib/format';
import type { CatalogCar } from '@/src/lib/types';
import { colors } from '@/src/theme/colors';

type CarCardVariant = 'full' | 'rail';

function StatusPill({ label }: { label: string }) {
  const dark = useColorScheme() === 'dark';
  const palette = colors[dark ? 'dark' : 'light'];
  const nativeGlass = Platform.OS === 'ios' && isGlassEffectAPIAvailable();
  const copy = <Text style={[styles.statusText, { color: palette.text }]}>{label}</Text>;

  if (nativeGlass) {
    return (
      <GlassView glassEffectStyle="regular" style={styles.statusPill}>
        {copy}
      </GlassView>
    );
  }

  return (
    <View style={[styles.statusPill, styles.webGlass, { borderColor: palette.hairline }]}>
      {copy}
    </View>
  );
}

export function CarCard({ car, variant = 'full' }: { car: CatalogCar; variant?: CarCardVariant }) {
  const dark = useColorScheme() === 'dark';
  const palette = colors[dark ? 'dark' : 'light'];
  const { width } = useWindowDimensions();
  const image = absoluteMediaUrl(car.coverUrl ?? car.variants?.[0]?.photos?.[0]?.url);
  const rail = variant === 'rail';
  const railWidth = Math.min(Math.max(width * 0.72, 250), 292);
  const label = statusLabel(car.status);

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${car.brand} ${car.model}`}
      onPress={() => router.push({ pathname: '/car/[slug]', params: { slug: car.slug } })}
      style={({ pressed }) => [styles.pressable, rail && { width: railWidth }, pressed && styles.pressed]}
    >
      <View
        style={[
          styles.imageWrap,
          rail ? styles.railImageWrap : styles.fullImageWrap,
          { backgroundColor: palette.elevated, borderColor: palette.hairline },
        ]}
      >
        {image ? <Image source={image} contentFit="contain" transition={160} style={StyleSheet.absoluteFill} /> : null}
        {label ? <View style={styles.statusPosition}><StatusPill label={label} /></View> : null}
      </View>

      <View style={[styles.copy, rail && styles.railCopy]}>
        <View style={styles.topline}>
          <Text numberOfLines={1} style={[styles.brand, { color: palette.secondary }]}>{car.brand.toUpperCase()}</Text>
          {car.year ? <Text style={[styles.year, { color: palette.tertiary }]}>{car.year}</Text> : null}
        </View>

        <Text numberOfLines={1} style={[rail ? styles.railModel : styles.model, { color: palette.text }]}>{car.model}</Text>
        {car.trim ? <Text numberOfLines={1} style={[styles.trim, { color: palette.secondary }]}>{car.trim}</Text> : null}

        <View style={styles.bottomline}>
          <Text numberOfLines={1} style={[styles.price, { color: palette.text }]}>{formatPrice(car)}</Text>
          <View style={[styles.disclosure, { backgroundColor: palette.fill }]}>
            <SymbolView
              name={{ ios: 'chevron.right', android: 'chevron_right', web: 'chevron_right' }}
              size={12}
              tintColor={palette.secondary}
              weight="semibold"
            />
          </View>
        </View>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  pressable: { width: '100%' },
  pressed: { transform: [{ scale: 0.988 }], opacity: 0.94 },
  imageWrap: { width: '100%', position: 'relative', overflow: 'hidden', borderWidth: StyleSheet.hairlineWidth },
  fullImageWrap: { aspectRatio: 1.48, borderRadius: 28 },
  railImageWrap: { aspectRatio: 1.42, borderRadius: 25 },
  statusPosition: { position: 'absolute', left: 12, top: 12 },
  statusPill: { minHeight: 30, borderRadius: 15, paddingHorizontal: 11, alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
  webGlass: { backgroundColor: 'rgba(248,248,250,0.84)', borderWidth: StyleSheet.hairlineWidth },
  statusText: { fontSize: 11, lineHeight: 14, fontWeight: '600', letterSpacing: -0.1 },
  copy: { paddingHorizontal: 3, paddingTop: 12, paddingBottom: 2 },
  railCopy: { paddingHorizontal: 2, paddingTop: 11 },
  topline: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 },
  brand: { flex: 1, fontSize: 10, lineHeight: 13, fontWeight: '700', letterSpacing: 0.75 },
  year: { fontSize: 12, lineHeight: 15, fontWeight: '500' },
  model: { marginTop: 3, fontSize: 22, lineHeight: 26, fontWeight: '700', letterSpacing: -0.65 },
  railModel: { marginTop: 3, fontSize: 18, lineHeight: 22, fontWeight: '700', letterSpacing: -0.45 },
  trim: { marginTop: 1, fontSize: 13, lineHeight: 18 },
  bottomline: { marginTop: 9, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 10 },
  price: { flex: 1, fontSize: 16, lineHeight: 20, fontWeight: '600', letterSpacing: -0.2 },
  disclosure: { width: 26, height: 26, borderRadius: 13, alignItems: 'center', justifyContent: 'center' },
});
