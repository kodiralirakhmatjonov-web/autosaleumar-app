import type { PropsWithChildren } from 'react';
import { Platform, StyleSheet, View, useColorScheme } from 'react-native';
import { GlassView, isGlassEffectAPIAvailable } from 'expo-glass-effect';
import { colors } from '@/src/theme/colors';

export function GlassPill({ children }: PropsWithChildren) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const canUseGlass = Platform.OS === 'ios' && isGlassEffectAPIAvailable();

  if (!canUseGlass) {
    return <View style={[styles.base, { backgroundColor: palette.elevated, borderColor: palette.hairline }]}>{children}</View>;
  }

  return (
    <GlassView glassEffectStyle="regular" isInteractive style={styles.base}>
      {children}
    </GlassView>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 48,
    borderRadius: 24,
    paddingHorizontal: 17,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
    borderWidth: StyleSheet.hairlineWidth,
  },
});
