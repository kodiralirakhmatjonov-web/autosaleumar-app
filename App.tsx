import React, {useMemo, useState} from 'react';
import {
  Alert,
  Linking,
  Platform,
  Pressable,
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TextInput,
  useColorScheme,
  View,
} from 'react-native';
import {WebView} from 'react-native-webview';
import {APP_SCHEME, SITE_ORIGIN} from './src/config';

type TabKey = 'home' | 'cars' | 'visit' | 'settings';
type ThemeMode = 'system' | 'light' | 'dark';
type Language = 'ru' | 'uz';


const APP_WEB_SHELL_SCRIPT = "(() => {\n  const STYLE_ID = 'asu-native-shell-style';\n  const HIDDEN_ATTR = 'data-asu-native-hidden';\n  const CSS = \"\\n:root {\\n  --asu-native-bottom-inset: 112px;\\n  --header-height: 0px !important;\\n  --nav-height: 0px !important;\\n}\\nhtml, body {\\n  margin-top: 0 !important;\\n  padding-top: 0 !important;\\n  overscroll-behavior-y: none;\\n}\\nbody {\\n  padding-bottom: var(--asu-native-bottom-inset) !important;\\n}\\nheader,\\n[role=\\\"banner\\\"],\\n[data-site-header],\\n[data-app-header],\\n[data-header-root],\\n[data-mobile-header] {\\n  display: none !important;\\n  visibility: hidden !important;\\n  height: 0 !important;\\n  min-height: 0 !important;\\n  max-height: 0 !important;\\n  margin: 0 !important;\\n  padding: 0 !important;\\n  border: 0 !important;\\n  overflow: hidden !important;\\n  pointer-events: none !important;\\n}\\n[data-asu-native-hidden=\\\"1\\\"] {\\n  display: none !important;\\n  visibility: hidden !important;\\n  height: 0 !important;\\n  min-height: 0 !important;\\n  max-height: 0 !important;\\n  margin: 0 !important;\\n  padding: 0 !important;\\n  border: 0 !important;\\n  overflow: hidden !important;\\n  pointer-events: none !important;\\n}\\n\";\n\n  const ensureStyle = () => {\n    let style = document.getElementById(STYLE_ID);\n    if (!style) {\n      style = document.createElement('style');\n      style.id = STYLE_ID;\n      style.textContent = CSS;\n      document.head.appendChild(style);\n    }\n  };\n\n  const hideTopChrome = () => {\n    const nodes = document.querySelectorAll(\n      'header, [role=\"banner\"], [data-site-header], [data-app-header], [data-header-root], [data-mobile-header], body > nav, #__next > nav, #root > nav'\n    );\n    nodes.forEach((node) => node.setAttribute(HIDDEN_ATTR, '1'));\n\n    const structuralCandidates = document.querySelectorAll('body > *, #__next > *, #root > *');\n    structuralCandidates.forEach((node) => {\n      if (!(node instanceof HTMLElement) || node.hasAttribute(HIDDEN_ATTR)) return;\n      const rect = node.getBoundingClientRect();\n      const style = window.getComputedStyle(node);\n      const text = (node.textContent || '').replace(/\\s+/g, ' ').trim();\n      const hasBrand = /AUTO\\s*SALE\\s*UMAR/i.test(text) || !!node.querySelector('img[alt*=\"Auto Sale Umar\" i]');\n      const hasMenuControl = !!node.querySelector('button[aria-label*=\"menu\" i], button[aria-label*=\"\u043c\u0435\u043d\u044e\" i], [data-menu-trigger], [aria-controls*=\"menu\" i]');\n      const topChrome = rect.top <= 20 && rect.height >= 48 && rect.height <= 190;\n      const anchored = style.position === 'fixed' || style.position === 'sticky' || topChrome;\n      if (topChrome && anchored && hasBrand && hasMenuControl) {\n        node.setAttribute(HIDDEN_ATTR, '1');\n      }\n    });\n  };\n\n  const apply = () => {\n    ensureStyle();\n    hideTopChrome();\n  };\n\n  apply();\n  new MutationObserver(apply).observe(document.documentElement, {childList: true, subtree: true});\n})();\ntrue;";

const TAB_PATHS: Record<Exclude<TabKey, 'settings'>, string> = {
  home: '/',
  cars: '/cars/',
  visit: '/booking/',
};

function withAppParams(path: string, language: Language, theme: ThemeMode) {
  const absolute = path.startsWith('http') ? path : `${SITE_ORIGIN}${path.startsWith('/') ? path : `/${path}`}`;
  const hashIndex = absolute.indexOf('#');
  const base = hashIndex >= 0 ? absolute.slice(0, hashIndex) : absolute;
  const hash = hashIndex >= 0 ? absolute.slice(hashIndex) : '';
  const separator = base.includes('?') ? '&' : '?';
  return `${base}${separator}asu_app=1&asu_lang=${language}&asu_theme=${theme}${hash}`;
}

function canStayInsideApp(url: string) {
  return url.startsWith('https://autosaleumar.com/') || url.startsWith('https://www.autosaleumar.com/');
}

export default function App() {
  const systemScheme = useColorScheme();
  const [tab, setTab] = useState<TabKey>('home');
  const [webPath, setWebPath] = useState('/');
  const [language, setLanguage] = useState<Language>('ru');
  const [themeMode, setThemeMode] = useState<ThemeMode>('system');
  const [metroUrl, setMetroUrl] = useState('');

  const dark = themeMode === 'dark' || (themeMode === 'system' && systemScheme === 'dark');
  const palette = dark ? DARK : LIGHT;

  const activeUrl = useMemo(() => {
    if (tab === 'settings') return null;
    return withAppParams(webPath, language, themeMode);
  }, [tab, webPath, language, themeMode]);

  const selectTab = (next: TabKey) => {
    if (next !== 'settings') setWebPath(TAB_PATHS[next]);
    setTab(next);
  };

  const openSitePath = (path: string) => {
    setWebPath(path);
    setTab('home');
  };

  const handleNavigation = (request: {url: string}) => {
    if (canStayInsideApp(request.url)) return true;
    if (/^(tel:|mailto:|sms:|whatsapp:|tg:|https:\/\/wa\.me|https:\/\/t\.me)/i.test(request.url)) {
      Linking.openURL(request.url).catch(() => {});
      return false;
    }
    if (/^https?:/i.test(request.url)) {
      Linking.openURL(request.url).catch(() => {});
      return false;
    }
    return true;
  };

  const saveMetro = async () => {
    const trimmed = metroUrl.trim().replace(/\/$/, '');
    if (!/^https:\/\//i.test(trimmed)) {
      Alert.alert('Metro URL', 'Вставьте HTTPS-адрес tunnel, например https://xxxx.trycloudflare.com');
      return;
    }
    const target = `${APP_SCHEME}://metro?url=${encodeURIComponent(trimmed)}`;
    try {
      await Linking.openURL(target);
      Alert.alert('Metro сохранён', 'Полностью закройте Auto Sale Umar и откройте приложение снова.');
    } catch {
      Alert.alert('Ошибка', 'Не удалось сохранить Metro URL.');
    }
  };

  const resetMetro = async () => {
    try {
      await Linking.openURL(`${APP_SCHEME}://metro-reset`);
      setMetroUrl('');
      Alert.alert('Metro отключён', 'После перезапуска приложение снова использует встроенный JS bundle.');
    } catch {
      Alert.alert('Ошибка', 'Не удалось сбросить Metro URL.');
    }
  };

  return (
    <SafeAreaView style={[styles.root, {backgroundColor: palette.bg}]}>
      <StatusBar barStyle={dark ? 'light-content' : 'dark-content'} />
      <View style={styles.content}>
        {tab !== 'settings' && activeUrl ? (
          <WebView
            key={`${tab}-${language}-${themeMode}`}
            source={{uri: activeUrl}}
            style={{backgroundColor: palette.bg}}
            injectedJavaScriptBeforeContentLoaded={APP_WEB_SHELL_SCRIPT}
            injectedJavaScript={APP_WEB_SHELL_SCRIPT}
            originWhitelist={['*']}
            allowsBackForwardNavigationGestures
            javaScriptEnabled
            domStorageEnabled
            sharedCookiesEnabled
            onShouldStartLoadWithRequest={handleNavigation}
            applicationNameForUserAgent="AutoSaleUmar-iOS"
            pullToRefreshEnabled={Platform.OS === 'ios'}
          />
        ) : (
          <SettingsScreen
            palette={palette}
            language={language}
            setLanguage={setLanguage}
            themeMode={themeMode}
            setThemeMode={setThemeMode}
            metroUrl={metroUrl}
            setMetroUrl={setMetroUrl}
            saveMetro={saveMetro}
            resetMetro={resetMetro}
            openSitePath={openSitePath}
          />
        )}
      </View>
      <BottomBar tab={tab} onSelect={selectTab} palette={palette} />
    </SafeAreaView>
  );
}

function BottomBar({tab, onSelect, palette}: {tab: TabKey; onSelect: (v: TabKey) => void; palette: Palette}) {
  const items: Array<[TabKey, string, string]> = [
    ['home', '⌂', 'Главная'],
    ['cars', '◇', 'Автомобили'],
    ['visit', '⊙', 'Визит'],
    ['settings', '⚙︎', 'Настройки'],
  ];

  return (
    <View pointerEvents="box-none" style={styles.bottomDock}>
      <View
        style={[
          styles.bottomBar,
          {
            backgroundColor: palette.glass,
            borderColor: palette.glassBorder,
            shadowColor: '#000000',
          },
        ]}>
        {items.map(([key, icon, label]) => {
          const active = tab === key;
          return (
            <Pressable
              key={key}
              onPress={() => onSelect(key)}
              accessibilityRole="button"
              accessibilityState={{selected: active}}
              hitSlop={4}
              style={({pressed}: {pressed: boolean}) => [
                styles.tabButton,
                active && {
                  backgroundColor: palette.glassActive,
                  borderColor: palette.glassActiveBorder,
                },
                pressed && styles.tabButtonPressed,
              ]}>
              <Text style={[styles.tabIcon, {color: active ? palette.text : palette.muted}]}>{icon}</Text>
              <Text style={[styles.tabLabel, {color: active ? palette.text : palette.muted}]}>{label}</Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

function SettingsScreen(props: {
  palette: Palette;
  language: Language;
  setLanguage: (v: Language) => void;
  themeMode: ThemeMode;
  setThemeMode: (v: ThemeMode) => void;
  metroUrl: string;
  setMetroUrl: (v: string) => void;
  saveMetro: () => void;
  resetMetro: () => void;
  openSitePath: (path: string) => void;
}) {
  const {palette} = props;
  return (
    <ScrollView style={{backgroundColor: palette.bg}} contentContainerStyle={styles.settings} keyboardShouldPersistTaps="handled">
      <Text style={[styles.kicker, {color: palette.muted}]}>AUTO SALE UMAR</Text>
      <Text style={[styles.title, {color: palette.text}]}>Настройки</Text>
      <Text style={[styles.subtitle, {color: palette.muted}]}>Единая цифровая экосистема автомобилей</Text>

      <Section title="Быстрый доступ" palette={palette}>
        <Row label="Control System" detail="Управление автомобилями" palette={palette} onPress={() => props.openSitePath('/admin/cars/')} />
        <Row label="Сотрудники" detail="Администраторы и менеджеры" palette={palette} onPress={() => props.openSitePath('/admin/staff/')} />
        <Row label="Шоурум" detail="Автомобили в шоуруме" palette={palette} onPress={() => props.openSitePath('/#showroom')} />
        <Row label="Контакты" palette={palette} onPress={() => props.openSitePath('/#contacts')} />
        <Row label="Забронировать визит" palette={palette} onPress={() => props.openSitePath('/booking/')} />
        <Row label="Получить рекомендацию" palette={palette} onPress={() => props.openSitePath('/request-car/')} last />
      </Section>

      <Section title="Язык" palette={palette}>
        <ChoiceRow label="Русский" selected={props.language === 'ru'} palette={palette} onPress={() => props.setLanguage('ru')} />
        <ChoiceRow label="O‘zbekcha" selected={props.language === 'uz'} palette={palette} onPress={() => props.setLanguage('uz')} last />
      </Section>

      <Section title="Оформление" palette={palette}>
        <ChoiceRow label="Системное" selected={props.themeMode === 'system'} palette={palette} onPress={() => props.setThemeMode('system')} />
        <ChoiceRow label="Светлое" selected={props.themeMode === 'light'} palette={palette} onPress={() => props.setThemeMode('light')} />
        <ChoiceRow label="Тёмное" selected={props.themeMode === 'dark'} palette={palette} onPress={() => props.setThemeMode('dark')} last />
      </Section>

      {__DEV__ ? (
        <View style={[styles.devCard, {backgroundColor: palette.card, borderColor: palette.line}]}>
          <Text style={[styles.sectionTitle, {color: palette.muted}]}>DEVELOPER · METRO</Text>
          <Text style={[styles.devText, {color: palette.text}]}>Запустите GitHub Actions → Auto Sale Umar Mobile CI → metro и вставьте выданный HTTPS URL. После сохранения перезапустите приложение.</Text>
          <TextInput
            value={props.metroUrl}
            onChangeText={props.setMetroUrl}
            autoCapitalize="none"
            autoCorrect={false}
            keyboardType="url"
            placeholder="https://xxxx.trycloudflare.com"
            placeholderTextColor={palette.muted}
            style={[styles.input, {color: palette.text, backgroundColor: palette.input, borderColor: palette.line}]}
          />
          <View style={styles.devButtons}>
            <Pressable style={[styles.primaryButton, {backgroundColor: palette.text}]} onPress={props.saveMetro}>
              <Text style={[styles.primaryButtonText, {color: palette.bg}]}>Сохранить Metro</Text>
            </Pressable>
            <Pressable style={[styles.secondaryButton, {borderColor: palette.line}]} onPress={props.resetMetro}>
              <Text style={{color: palette.text, fontWeight: '700'}}>Сбросить</Text>
            </Pressable>
          </View>
        </View>
      ) : null}
      <Text style={[styles.footer, {color: palette.muted}]}>Auto Sale Umar · iOS native client</Text>
    </ScrollView>
  );
}

function Section({title, palette, children}: {title: string; palette: Palette; children: React.ReactNode}) {
  return (
    <View style={styles.sectionWrap}>
      <Text style={[styles.sectionTitle, {color: palette.muted}]}>{title.toUpperCase()}</Text>
      <View style={[styles.section, {backgroundColor: palette.card, borderColor: palette.line}]}>{children}</View>
    </View>
  );
}

function Row({label, detail, palette, onPress, last}: {label: string; detail?: string; palette: Palette; onPress: () => void; last?: boolean}) {
  return (
    <Pressable style={[styles.row, !last && {borderBottomColor: palette.line, borderBottomWidth: StyleSheet.hairlineWidth}]} onPress={onPress}>
      <View style={{flex: 1}}>
        <Text style={[styles.rowLabel, {color: palette.text}]}>{label}</Text>
        {detail ? <Text style={[styles.rowDetail, {color: palette.muted}]}>{detail}</Text> : null}
      </View>
      <Text style={[styles.chevron, {color: palette.muted}]}>›</Text>
    </Pressable>
  );
}

function ChoiceRow({label, selected, palette, onPress, last}: {label: string; selected: boolean; palette: Palette; onPress: () => void; last?: boolean}) {
  return (
    <Pressable style={[styles.choiceRow, !last && {borderBottomColor: palette.line, borderBottomWidth: StyleSheet.hairlineWidth}]} onPress={onPress}>
      <Text style={[styles.rowLabel, {color: palette.text}]}>{label}</Text>
      <Text style={[styles.check, {color: selected ? palette.text : 'transparent'}]}>✓</Text>
    </Pressable>
  );
}

type Palette = {
  bg: string;
  card: string;
  input: string;
  text: string;
  muted: string;
  line: string;
  glass: string;
  glassBorder: string;
  glassActive: string;
  glassActiveBorder: string;
};
const LIGHT: Palette = {
  bg: '#F6F6F4',
  card: '#FFFFFF',
  input: '#F4F4F4',
  text: '#111111',
  muted: '#77777C',
  line: '#E4E4E2',
  glass: 'rgba(246,246,246,0.78)',
  glassBorder: 'rgba(255,255,255,0.82)',
  glassActive: 'rgba(255,255,255,0.94)',
  glassActiveBorder: 'rgba(255,255,255,0.98)',
};
const DARK: Palette = {
  bg: '#0B0B0C',
  card: '#161618',
  input: '#222225',
  text: '#F7F7F7',
  muted: '#929297',
  line: '#2B2B2F',
  glass: 'rgba(24,24,27,0.80)',
  glassBorder: 'rgba(255,255,255,0.10)',
  glassActive: 'rgba(255,255,255,0.12)',
  glassActiveBorder: 'rgba(255,255,255,0.16)',
};

const styles = StyleSheet.create({
  root: {flex: 1},
  content: {flex: 1},
  bottomDock: {position: 'absolute', left: 12, right: 12, bottom: 8, zIndex: 50},
  bottomBar: {
    height: 72,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 30,
    borderWidth: StyleSheet.hairlineWidth,
    padding: 5,
    shadowOffset: {width: 0, height: 10},
    shadowOpacity: 0.17,
    shadowRadius: 24,
    elevation: 14,
  },
  tabButton: {
    flex: 1,
    height: 60,
    borderRadius: 25,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: 'transparent',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 2,
  },
  tabButtonPressed: {opacity: 0.72, transform: [{scale: 0.98}]},
  tabIcon: {fontSize: 21, lineHeight: 23, fontWeight: '600'},
  tabLabel: {fontSize: 10.5, lineHeight: 13, fontWeight: '600'},
  settings: {paddingHorizontal: 18, paddingTop: 24, paddingBottom: 126},
  kicker: {fontSize: 11, letterSpacing: 1.8, fontWeight: '800'},
  title: {fontSize: 34, lineHeight: 40, fontWeight: '800', marginTop: 8},
  subtitle: {fontSize: 15, lineHeight: 21, marginTop: 5, marginBottom: 24},
  sectionWrap: {marginBottom: 23}, sectionTitle: {fontSize: 11, letterSpacing: 0.8, fontWeight: '800', marginBottom: 8, marginLeft: 4},
  section: {borderRadius: 22, borderWidth: StyleSheet.hairlineWidth, overflow: 'hidden'},
  row: {minHeight: 62, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 17, paddingVertical: 11},
  rowLabel: {fontSize: 16, fontWeight: '600'}, rowDetail: {fontSize: 12.5, marginTop: 3}, chevron: {fontSize: 28, marginLeft: 12, marginTop: -2},
  choiceRow: {minHeight: 54, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 17}, check: {fontSize: 18, fontWeight: '800'},
  devCard: {borderRadius: 22, borderWidth: StyleSheet.hairlineWidth, padding: 16, marginBottom: 22},
  devText: {fontSize: 13.5, lineHeight: 19, marginBottom: 12},
  input: {height: 46, borderWidth: StyleSheet.hairlineWidth, borderRadius: 13, paddingHorizontal: 12, fontSize: 13},
  devButtons: {flexDirection: 'row', gap: 9, marginTop: 10}, primaryButton: {flex: 1, height: 44, borderRadius: 13, alignItems: 'center', justifyContent: 'center'}, primaryButtonText: {fontWeight: '800'}, secondaryButton: {height: 44, paddingHorizontal: 18, borderRadius: 13, borderWidth: StyleSheet.hairlineWidth, alignItems: 'center', justifyContent: 'center'},
  footer: {fontSize: 11.5, textAlign: 'center', marginTop: 4},
});
