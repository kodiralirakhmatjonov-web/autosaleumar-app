import { SymbolView } from 'expo-symbols';
import { StyleSheet, Text, View, useColorScheme } from 'react-native';
import { colors } from '@/src/theme/colors';

export default function SavedScreen() {
  const palette = colors[useColorScheme() === 'dark' ? 'dark' : 'light'];
  return (
    <View style={[styles.root, { backgroundColor: palette.background }]}> 
      <View style={styles.shell}>
        <Text style={[styles.title, { color: palette.text }]}>Избранное</Text>
        <View style={[styles.emptyCard, { backgroundColor: palette.surface, borderColor: palette.hairline }]}> 
          <View style={[styles.iconCircle, { backgroundColor: palette.fill }]}> 
            <SymbolView name={{ ios: 'heart', android: 'favorite', web: 'favorite' }} size={28} tintColor={palette.text} />
          </View>
          <Text style={[styles.emptyTitle, { color: palette.text }]}>Сохраняйте автомобили</Text>
          <Text style={[styles.text, { color: palette.secondary }]}>Избранное будет доступно без обязательной регистрации. Мы подключим хранение на следующем этапе.</Text>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, paddingHorizontal: 16, paddingTop: 34 },
  shell: { width: '100%', maxWidth: 720, alignSelf: 'center' },
  title: { fontSize: 34, lineHeight: 39, fontWeight: '700', letterSpacing: -1.2 },
  emptyCard: { marginTop: 22, borderRadius: 28, borderWidth: StyleSheet.hairlineWidth, padding: 24, alignItems: 'flex-start' },
  iconCircle: { width: 58, height: 58, borderRadius: 29, alignItems: 'center', justifyContent: 'center' },
  emptyTitle: { marginTop: 20, fontSize: 23, lineHeight: 27, fontWeight: '700', letterSpacing: -0.55 },
  text: { marginTop: 9, maxWidth: 520, fontSize: 16, lineHeight: 23 },
});
