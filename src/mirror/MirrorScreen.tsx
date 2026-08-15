import { StyleSheet, View } from 'react-native';
import SiteMirror from '@/src/mirror/SiteMirror';
import { useApp } from '@/src/state/AppProvider';

function withAppMode(path: string, language: string, theme: string) {
  const hashIndex = path.indexOf('#');
  const basePath = hashIndex >= 0 ? path.slice(0, hashIndex) : path;
  const hash = hashIndex >= 0 ? path.slice(hashIndex) : '';
  const separator = basePath.includes('?') ? '&' : '?';
  return `${basePath}${separator}asu_app=1&asu_lang=${encodeURIComponent(language)}&asu_theme=${encodeURIComponent(theme)}${hash}`;
}

export default function MirrorScreen({ path }: { path: string }) {
  const { language, themeMode } = useApp();
  const appPath = withAppMode(path, language, themeMode);

  return (
    <View style={styles.page}>
      <SiteMirror
        key={appPath}
        path={appPath}
        dom={{
          style: styles.dom,
          containerStyle: styles.dom,
          scrollEnabled: true,
          sharedCookiesEnabled: true,
          thirdPartyCookiesEnabled: true,
          allowsInlineMediaPlayback: true,
          mediaPlaybackRequiresUserAction: false,
        } as any}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  page: { flex: 1, backgroundColor: '#f4f4f2' },
  dom: { flex: 1, width: '100%', height: '100%' },
});
