import { GlassView, isGlassEffectAPIAvailable } from 'expo-glass-effect';
import type { PropsWithChildren } from 'react';
import {
  Platform,
  StyleSheet,
  View,
  useColorScheme,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import { colors } from '@/src/theme/colors';

type AdaptiveGlassProps = PropsWithChildren<{
  style?: StyleProp<ViewStyle>;
  interactive?: boolean;
  dark?: boolean;
  tintColor?: string;
}>;

const webLightGlass = {
  backgroundColor: 'rgba(248,248,250,0.76)',
  borderColor: 'rgba(255,255,255,0.82)',
  borderWidth: 1,
  boxShadow: '0 14px 42px rgba(0,0,0,0.10), inset 0 0 0 0.5px rgba(0,0,0,0.05)',
  backdropFilter: 'blur(26px) saturate(180%)',
  WebkitBackdropFilter: 'blur(26px) saturate(180%)',
} as any;

const webDarkGlass = {
  backgroundColor: 'rgba(24,24,27,0.70)',
  borderColor: 'rgba(255,255,255,0.16)',
  borderWidth: 1,
  boxShadow: '0 14px 42px rgba(0,0,0,0.20), inset 0 0 0 0.5px rgba(255,255,255,0.08)',
  backdropFilter: 'blur(28px) saturate(160%)',
  WebkitBackdropFilter: 'blur(28px) saturate(160%)',
} as any;

export function AdaptiveGlass({ children, style, interactive = false, dark = false, tintColor }: AdaptiveGlassProps) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const nativeGlass = Platform.OS === 'ios' && isGlassEffectAPIAvailable();

  if (nativeGlass) {
    return (
      <GlassView
        isInteractive={interactive}
        glassEffectStyle="regular"
        tintColor={tintColor ?? (dark ? 'rgba(20,20,22,0.58)' : undefined)}
        style={[styles.base, style]}
      >
        {children}
      </GlassView>
    );
  }

  const fallback = Platform.OS === 'web'
    ? (dark ? webDarkGlass : webLightGlass)
    : {
        backgroundColor: dark ? 'rgba(28,28,30,0.92)' : palette.elevated,
        borderColor: dark ? 'rgba(255,255,255,0.12)' : palette.hairline,
        borderWidth: StyleSheet.hairlineWidth,
      };

  return <View style={[styles.base, fallback, style]}>{children}</View>;
}

const styles = StyleSheet.create({
  base: { overflow: 'hidden' },
});
