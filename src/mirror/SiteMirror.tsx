'use dom';

import { useEffect, useMemo } from 'react';

const SITE_ORIGIN = 'https://autosaleumar.com';

export type SiteMirrorProps = {
  path?: string;
  dom?: any;
};

function normalizePath(path: string) {
  if (!path) return '/';
  return path.startsWith('/') ? path : `/${path}`;
}

export default function SiteMirror({ path = '/' }: SiteMirrorProps) {
  const url = useMemo(() => `${SITE_ORIGIN}${normalizePath(path)}`, [path]);
  const hostOS = process.env.EXPO_DOM_HOST_OS;

  useEffect(() => {
    document.documentElement.style.width = '100%';
    document.documentElement.style.height = '100%';
    document.documentElement.style.margin = '0';
    document.documentElement.style.padding = '0';
    document.body.style.width = '100%';
    document.body.style.height = '100%';
    document.body.style.margin = '0';
    document.body.style.padding = '0';
    document.body.style.overflow = 'hidden';
    document.body.style.background = '#f4f4f2';

    // Native Expo DOM components run inside their own WebView. Navigating that
    // WebView to the production site preserves the exact Next.js/CSS/Cloudflare
    // experience instead of approximating it with React Native styles.
    if (hostOS === 'ios' || hostOS === 'android') {
      window.location.replace(url);
    }
  }, [hostOS, url]);

  if (hostOS === 'ios' || hostOS === 'android') {
    return (
      <main
        style={{
          width: '100%',
          height: '100%',
          display: 'grid',
          placeItems: 'center',
          background: '#f4f4f2',
          color: '#8e8e93',
          fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif',
          fontSize: 13,
        }}
      >
        Auto Sale Umar
      </main>
    );
  }

  // Expo Web: keep the production website in an iframe so the browser preview
  // is also pixel-for-pixel the same website, with its real APIs and media.
  return (
    <iframe
      key={url}
      src={url}
      title="Auto Sale Umar"
      allow="autoplay; fullscreen; clipboard-read; clipboard-write"
      allowFullScreen
      style={{
        display: 'block',
        width: '100%',
        height: '100%',
        border: 0,
        margin: 0,
        padding: 0,
        background: '#f4f4f2',
      }}
    />
  );
}
