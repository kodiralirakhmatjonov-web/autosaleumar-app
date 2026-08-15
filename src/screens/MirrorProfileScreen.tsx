import { useRouter } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useApp } from '@/src/state/AppProvider';

type SegmentValue = 'system' | 'light' | 'dark';
type RowIcon =
  | 'person.crop.circle'
  | 'rectangle.3.group'
  | 'person.2'
  | 'building.2'
  | 'phone'
  | 'calendar'
  | 'sparkles';

function SectionLabel({ children, muted }: { children: string; muted: string }) {
  return <Text style={[styles.sectionLabel, { color: muted }]}>{children}</Text>;
}

function Row({
  icon,
  fallback,
  title,
  subtitle,
  onPress,
  text,
  muted,
  surface,
  line,
}: {
  icon: RowIcon;
  fallback: 'person' | 'dashboard' | 'people' | 'storefront' | 'phone' | 'event_available' | 'auto_awesome';
  title: string;
  subtitle: string;
  onPress: () => void;
  text: string;
  muted: string;
  surface: string;
  line: string;
}) {
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.row, { backgroundColor: surface, borderColor: line }, pressed && styles.pressed]}>
      <View style={[styles.iconWell, { borderColor: line }]}>
        <SymbolView name={{ ios: icon, android: fallback, web: fallback }} size={20} tintColor={text} weight="semibold" />
      </View>
      <View style={styles.rowCopy}>
        <Text style={[styles.rowTitle, { color: text }]}>{title}</Text>
        <Text style={[styles.rowSubtitle, { color: muted }]}>{subtitle}</Text>
      </View>
      <SymbolView name={{ ios: 'chevron.right', android: 'chevron_right', web: 'chevron_right' }} size={17} tintColor={muted} weight="semibold" />
    </Pressable>
  );
}

export default function MirrorProfileScreen() {
  const router = useRouter();
  const { language, setLanguage, themeMode, setThemeMode, resolvedTheme } = useApp();
  const dark = resolvedTheme === 'dark';

  const background = dark ? '#09090a' : '#f4f4f2';
  const text = dark ? '#f5f5f7' : '#111214';
  const muted = dark ? '#a1a1a6' : '#7d7d82';
  const surface = dark ? 'rgba(28,28,30,.88)' : 'rgba(255,255,255,.86)';
  const soft = dark ? 'rgba(44,44,46,.72)' : 'rgba(246,246,244,.84)';
  const line = dark ? 'rgba(255,255,255,.10)' : 'rgba(60,60,67,.12)';
  const selected = dark ? '#f5f5f7' : '#111214';
  const selectedText = dark ? '#111214' : '#ffffff';

  const themeItems: Array<{ value: SegmentValue; label: string }> = [
    { value: 'system', label: 'Система' },
    { value: 'light', label: 'Светлая' },
    { value: 'dark', label: 'Тёмная' },
  ];

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: background }}
      contentContainerStyle={styles.content}
      showsVerticalScrollIndicator={false}
      contentInsetAdjustmentBehavior="automatic"
    >
      <Text style={[styles.kicker, { color: muted }]}>AUTO SALE UMAR</Text>
      <Text style={[styles.title, { color: text }]}>Настройки</Text>
      <Text style={[styles.lead, { color: muted }]}>Навигация приложения, Control System, язык и оформление.</Text>

      <SectionLabel muted={muted}>ИНТЕРФЕЙС</SectionLabel>
      <View style={styles.group}>
        <Row icon="person.crop.circle" fallback="person" title="Клиент" subtitle="Главная и каталог автомобилей" onPress={() => router.replace('/')} text={text} muted={muted} surface={surface} line={line} />
        <Row icon="rectangle.3.group" fallback="dashboard" title="Control System" subtitle="Панель управления автомобилями" onPress={() => router.push('/admin/cars')} text={text} muted={muted} surface={surface} line={line} />
        <Row icon="person.2" fallback="people" title="Сотрудники" subtitle="Команда, роли и доступ" onPress={() => router.push('/admin/staff')} text={text} muted={muted} surface={surface} line={line} />
      </View>

      <SectionLabel muted={muted}>ШОУРУМ И СЕРВИС</SectionLabel>
      <View style={styles.group}>
        <Row icon="building.2" fallback="storefront" title="Шоурум" subtitle="Атмосфера и автомобили в шоуруме" onPress={() => router.push('/showroom')} text={text} muted={muted} surface={surface} line={line} />
        <Row icon="phone" fallback="phone" title="Контакты" subtitle="Связаться с Auto Sale Umar" onPress={() => router.push('/contacts')} text={text} muted={muted} surface={surface} line={line} />
        <Row icon="calendar" fallback="event_available" title="Забронировать визит" subtitle="Выбрать дату и время посещения" onPress={() => router.push('/booking')} text={text} muted={muted} surface={surface} line={line} />
        <Row icon="sparkles" fallback="auto_awesome" title="Получить рекомендацию" subtitle="Оставить запрос на персональный подбор автомобиля" onPress={() => router.push('/request-car')} text={text} muted={muted} surface={surface} line={line} />
      </View>

      <SectionLabel muted={muted}>ЯЗЫК</SectionLabel>
      <View style={[styles.segment, { backgroundColor: soft, borderColor: line }]}>
        {(['ru', 'uz'] as const).map((value) => (
          <Pressable key={value} onPress={() => setLanguage(value)} style={[styles.segmentButton, language === value && { backgroundColor: selected }]}>
            <Text style={[styles.segmentText, { color: language === value ? selectedText : muted }]}>{value === 'ru' ? 'Русский' : 'O‘zbek'}</Text>
          </Pressable>
        ))}
      </View>

      <SectionLabel muted={muted}>ОФОРМЛЕНИЕ</SectionLabel>
      <View style={[styles.segment, { backgroundColor: soft, borderColor: line }]}>
        {themeItems.map((item) => (
          <Pressable key={item.value} onPress={() => setThemeMode(item.value)} style={[styles.segmentButton, themeMode === item.value && { backgroundColor: selected }]}>
            <Text style={[styles.segmentText, { color: themeMode === item.value ? selectedText : muted }]}>{item.label}</Text>
          </Pressable>
        ))}
      </View>

      <View style={[styles.note, { backgroundColor: surface, borderColor: line }]}>
        <SymbolView name={{ ios: 'sparkles', android: 'auto_awesome', web: 'auto_awesome' }} size={18} tintColor={muted} weight="semibold" />
        <Text style={[styles.noteText, { color: muted }]}>Верхняя панель сайта в мобильном режиме отключена на всех страницах. Управление интерфейсом находится только здесь.</Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 18, paddingTop: 22, paddingBottom: 120 },
  kicker: { fontSize: 10, lineHeight: 13, fontWeight: '800', letterSpacing: 2.1 },
  title: { marginTop: 8, fontSize: 42, lineHeight: 45, fontWeight: '700', letterSpacing: -1.7 },
  lead: { maxWidth: 520, marginTop: 10, fontSize: 16, lineHeight: 23, fontWeight: '400' },
  sectionLabel: { marginTop: 30, marginBottom: 9, marginLeft: 4, fontSize: 10, lineHeight: 13, fontWeight: '800', letterSpacing: 1.7 },
  group: { gap: 8 },
  row: { minHeight: 76, paddingHorizontal: 14, paddingVertical: 11, borderWidth: StyleSheet.hairlineWidth, borderRadius: 26, flexDirection: 'row', alignItems: 'center', gap: 12 },
  pressed: { opacity: 0.68, transform: [{ scale: 0.992 }] },
  iconWell: { width: 48, height: 48, borderWidth: StyleSheet.hairlineWidth, borderRadius: 24, alignItems: 'center', justifyContent: 'center' },
  rowCopy: { flex: 1, minWidth: 0 },
  rowTitle: { fontSize: 16, lineHeight: 20, fontWeight: '600', letterSpacing: -0.25 },
  rowSubtitle: { marginTop: 3, fontSize: 12.5, lineHeight: 17, fontWeight: '400' },
  segment: { minHeight: 52, padding: 4, borderWidth: StyleSheet.hairlineWidth, borderRadius: 26, flexDirection: 'row', gap: 4 },
  segmentButton: { flex: 1, minHeight: 42, paddingHorizontal: 8, borderRadius: 21, alignItems: 'center', justifyContent: 'center' },
  segmentText: { fontSize: 12.5, lineHeight: 16, fontWeight: '600' },
  note: { marginTop: 28, padding: 16, borderWidth: StyleSheet.hairlineWidth, borderRadius: 24, flexDirection: 'row', alignItems: 'flex-start', gap: 10 },
  noteText: { flex: 1, fontSize: 12.5, lineHeight: 18 },
});
