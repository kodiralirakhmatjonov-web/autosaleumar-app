import { StyleSheet, View } from 'react-native';
import SiteMirror from '@/src/mirror/SiteMirror';

export default function MirrorScreen({ path }: { path: string }) {
  return (
    <View style={styles.page}>
      <SiteMirror
        key={path}
        path={path}
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
