import { Platform, PlatformColor, type ColorValue } from 'react-native';

function systemColor(name: string, fallback: string): ColorValue {
  return Platform.OS === 'ios' ? PlatformColor(name) : fallback;
}

export const colors = {
  light: {
    background: systemColor('systemGroupedBackground', '#F5F5F7'),
    surface: systemColor('secondarySystemGroupedBackground', '#FFFFFF'),
    elevated: systemColor('systemBackground', '#FFFFFF'),
    text: systemColor('label', '#111111'),
    secondary: systemColor('secondaryLabel', '#6E6E73'),
    tertiary: systemColor('tertiaryLabel', '#8E8E93'),
    fill: systemColor('tertiarySystemFill', 'rgba(118,118,128,0.12)'),
    hairline: systemColor('separator', 'rgba(60,60,67,0.16)'),
    accent: systemColor('systemBlue', '#007AFF'),
  },
  dark: {
    background: systemColor('systemGroupedBackground', '#000000'),
    surface: systemColor('secondarySystemGroupedBackground', '#1C1C1E'),
    elevated: systemColor('systemBackground', '#000000'),
    text: systemColor('label', '#F5F5F7'),
    secondary: systemColor('secondaryLabel', '#A1A1A6'),
    tertiary: systemColor('tertiaryLabel', '#8E8E93'),
    fill: systemColor('tertiarySystemFill', 'rgba(118,118,128,0.24)'),
    hairline: systemColor('separator', 'rgba(84,84,88,0.65)'),
    accent: systemColor('systemBlue', '#0A84FF'),
  },
} as const;
