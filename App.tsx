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
    ['cars', '▣', 'Автомобили'],
    ['visit', '⌖', 'Визит'],
    ['settings', '⚙', 'Настройки'],
  ];
  return (
    <View style={[styles.bottomBar, {backgroundColor: palette.bar, borderTopColor: palette.line}]}>
      {items.map(([key, icon, label]) => {
        const active = tab === key;
        return (
          <Pressable key={key} style={styles.tabButton} onPress={() => onSelect(key)} accessibilityRole="button">
            <Text style={[styles.tabIcon, {color: active ? palette.text : palette.muted}]}>{icon}</Text>
            <Text style={[styles.tabLabel, {color: active ? palette.text : palette.muted}]}>{label}</Text>
          </Pressable>
        );
      })}
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

type Palette = {bg: string; card: string; bar: string; input: string; text: string; muted: string; line: string};
const LIGHT: Palette = {bg: '#F6F6F4', card: '#FFFFFF', bar: 'rgba(255,255,255,0.96)', input: '#F4F4F4', text: '#111111', muted: '#737373', line: '#E4E4E2'};
const DARK: Palette = {bg: '#0B0B0C', card: '#161618', bar: 'rgba(18,18,20,0.97)', input: '#222225', text: '#F7F7F7', muted: '#929297', line: '#2B2B2F'};

const styles = StyleSheet.create({
  root: {flex: 1}, content: {flex: 1},
  bottomBar: {height: 72, flexDirection: 'row', borderTopWidth: StyleSheet.hairlineWidth, paddingBottom: 6},
  tabButton: {flex: 1, alignItems: 'center', justifyContent: 'center', gap: 3},
  tabIcon: {fontSize: 23, lineHeight: 26, fontWeight: '600'}, tabLabel: {fontSize: 10.5, fontWeight: '600'},
  settings: {paddingHorizontal: 18, paddingTop: 24, paddingBottom: 42},
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
