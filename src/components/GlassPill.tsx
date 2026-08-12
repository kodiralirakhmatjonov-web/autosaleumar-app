import type { PropsWithChildren } from 'react';
import { Platform, StyleSheet, View } from 'react-native';
import { GlassView, isGlassEffectAPIAvailable } from 'expo-glass-effect';

export function GlassPill({ children }: PropsWithChildren) {
  const canUseGlass = Platform.OS === 'ios' && isGlassEffectAPIAvailable();
  if (!canUseGlass) return <View style={[styles.base, styles.fallback]}>{children}</View>;
  return (
    <GlassView glassEffectStyle="regular" isInteractive style={styles.base}>
      {children}
    </GlassView>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 52,
    borderRadius: 28,
    paddingHorizontal: 18,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  fallback: {
    backgroundColor: 'rgba(255,255,255,0.88)',
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: 'rgba(60,60,67,0.18)',
  },
});
