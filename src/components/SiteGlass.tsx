import { BlurView } from 'expo-blur';
import { GlassView, isGlassEffectAPIAvailable } from 'expo-glass-effect';
import type { PropsWithChildren } from 'react';
import { Platform, StyleSheet, View, useColorScheme, type StyleProp, type ViewStyle } from 'react-native';

type Props = PropsWithChildren<{ style?: StyleProp<ViewStyle>; interactive?: boolean; dark?: boolean; intensity?: number }>;

export function SiteGlass({ children, style, interactive = false, dark = false, intensity = 72 }: Props) {
  const systemDark = useColorScheme() === 'dark';
  const effectiveDark = dark || systemDark;
  if (Platform.OS === 'ios' && isGlassEffectAPIAvailable()) {
    return (
      <GlassView
        isInteractive={interactive}
        glassEffectStyle="regular"
        tintColor={effectiveDark ? 'rgba(16,17,18,0.32)' : 'rgba(255,255,255,0.10)'}
        style={[styles.base, style]}
      >
        {children}
      </GlassView>
    );
  }
  return (
    <View style={[styles.base, styles.fallbackFrame, effectiveDark ? styles.darkFrame : styles.lightFrame, style]}>
      <BlurView intensity={intensity} tint={effectiveDark ? 'dark' : 'light'} style={StyleSheet.absoluteFill} />
      <View pointerEvents="none" style={[StyleSheet.absoluteFill, effectiveDark ? styles.darkWash : styles.lightWash]} />
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  base: { overflow: 'hidden' },
  fallbackFrame: { borderWidth: StyleSheet.hairlineWidth },
  lightFrame: { borderColor: 'rgba(255,255,255,0.82)', shadowColor: '#000', shadowOpacity: 0.10, shadowRadius: 24, shadowOffset: { width: 0, height: 12 } },
  darkFrame: { borderColor: 'rgba(255,255,255,0.14)', shadowColor: '#000', shadowOpacity: 0.28, shadowRadius: 26, shadowOffset: { width: 0, height: 14 } },
  lightWash: { backgroundColor: 'rgba(248,248,247,0.38)' },
  darkWash: { backgroundColor: 'rgba(18,19,20,0.34)' },
});
