import { useState } from 'react';
import { Pressable, StyleSheet, Text, View, useColorScheme } from 'react-native';
import MirrorScreen from '@/src/mirror/MirrorScreen';

export default function MirrorProfileScreen() {
  const dark = useColorScheme() === 'dark';
  const [mode, setMode] = useState<'client' | 'control'>('client');
  const background = dark ? '#09090a' : '#f4f4f2';
  const text = dark ? '#f5f5f7' : '#111214';
  const muted = dark ? '#a1a1a6' : '#7d7d82';
  const surface = dark ? 'rgba(36,36,38,.88)' : 'rgba(255,255,255,.88)';
  const selected = dark ? '#f5f5f7' : '#111214';
  const selectedText = dark ? '#111214' : '#ffffff';

  return (
    <View style={[styles.page, { backgroundColor: background }]}>
      <View style={styles.topArea}>
        <Text style={[styles.kicker, { color: muted }]}>AUTO SALE UMAR</Text>
        <Text style={[styles.title, { color: text }]}>Профиль</Text>
        <View style={[styles.segment, { backgroundColor: surface }]}>
          <Pressable
            onPress={() => setMode('client')}
            style={[styles.segmentButton, mode === 'client' && { backgroundColor: selected }]}
          >
            <Text style={[styles.segmentLabel, { color: mode === 'client' ? selectedText : muted }]}>Клиент</Text>
          </Pressable>
          <Pressable
            onPress={() => setMode('control')}
            style={[styles.segmentButton, mode === 'control' && { backgroundColor: selected }]}
          >
            <Text style={[styles.segmentLabel, { color: mode === 'control' ? selectedText : muted }]}>Control System</Text>
          </Pressable>
        </View>
      </View>
      <View style={styles.mirrorWrap}>
        <MirrorScreen key={mode} path={mode === 'client' ? '/' : '/admin/'} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  page: { flex: 1 },
  topArea: { paddingHorizontal: 16, paddingTop: 14, paddingBottom: 10 },
  kicker: { fontSize: 9, lineHeight: 12, fontWeight: '700', letterSpacing: 1.7 },
  title: { marginTop: 5, fontSize: 32, lineHeight: 36, fontWeight: '700', letterSpacing: -1.1 },
  segment: {
    marginTop: 12,
    height: 46,
    padding: 4,
    borderRadius: 23,
    flexDirection: 'row',
    gap: 4,
  },
  segmentButton: { flex: 1, borderRadius: 19, alignItems: 'center', justifyContent: 'center' },
  segmentLabel: { fontSize: 13, lineHeight: 17, fontWeight: '600' },
  mirrorWrap: { flex: 1, overflow: 'hidden' },
});
