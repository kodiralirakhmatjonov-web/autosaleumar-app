import type { ComponentProps, PropsWithChildren } from 'react';
import { Platform, Pressable, StyleSheet, Text, View, useColorScheme, type ViewStyle } from 'react-native';
import { GlassView, isGlassEffectAPIAvailable } from 'expo-glass-effect';
import { SymbolView } from 'expo-symbols';
import { colors } from '@/src/theme/colors';

type AppleGlassButtonProps = PropsWithChildren<{
  label: string;
  symbol?: ComponentProps<typeof SymbolView>['name'];
  onPress?: () => void;
  prominent?: boolean;
  style?: ViewStyle;
}>;

export function AppleGlassButton({ label, symbol, onPress, prominent = false, style }: AppleGlassButtonProps) {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  const canUseNativeGlass = Platform.OS === 'ios' && isGlassEffectAPIAvailable();
  const foreground = prominent ? '#FFFFFF' : palette.text;

  const content = (
    <View style={styles.content}>
      <Text style={[styles.label, { color: foreground }]}>{label}</Text>
      {symbol ? <SymbolView name={symbol} size={15} tintColor={foreground} /> : null}
    </View>
  );

  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.pressable, style, pressed && styles.pressed]}>
      {canUseNativeGlass ? (
        <GlassView
          isInteractive
          glassEffectStyle={prominent ? 'regular' : 'clear'}
          tintColor={prominent ? 'rgba(0,0,0,0.72)' : undefined}
          style={styles.surface}
        >
          {content}
        </GlassView>
      ) : (
        <View
          style={[
            styles.surface,
            {
              backgroundColor: prominent ? '#111113' : palette.elevated,
              borderColor: palette.hairline,
              borderWidth: prominent ? 0 : StyleSheet.hairlineWidth,
            },
          ]}
        >
          {content}
        </View>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  pressable: { alignSelf: 'flex-start' },
  pressed: { transform: [{ scale: 0.975 }] },
  surface: {
    minHeight: 48,
    borderRadius: 24,
    paddingHorizontal: 17,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  content: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8 },
  label: { fontSize: 15, fontWeight: '600', letterSpacing: -0.15 },
});
