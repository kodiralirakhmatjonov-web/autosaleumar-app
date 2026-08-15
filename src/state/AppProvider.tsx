import { createContext, useCallback, useContext, useEffect, useMemo, useState, type PropsWithChildren } from 'react';
import { useColorScheme } from 'react-native';
import { getMe, loginStaff, logoutStaff } from '@/src/lib/api';
import { storageDelete, storageGet, storageSet } from '@/src/lib/storage';
import type { Language, StaffUser, ThemeMode } from '@/src/lib/types';

const TOKEN_KEY = 'asu-mobile-token';
const FAVORITES_KEY = 'asu-mobile-favorites';
const LANGUAGE_KEY = 'asu-mobile-language';
const THEME_KEY = 'asu-mobile-theme';
const INTRO_KEY = 'asu-mobile-intro-seen';

type ControlMode = 'client' | 'control';

interface AppContextValue {
  ready: boolean;
  language: Language;
  setLanguage: (value: Language) => void;
  themeMode: ThemeMode;
  setThemeMode: (value: ThemeMode) => void;
  resolvedTheme: 'light' | 'dark';
  favorites: string[];
  toggleFavorite: (slug: string) => void;
  isFavorite: (slug: string) => boolean;
  introSeen: boolean;
  markIntroSeen: () => void;
  token: string | null;
  user: StaffUser | null;
  controlMode: ControlMode;
  setControlMode: (value: ControlMode) => void;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  refreshMe: () => Promise<void>;
}

const AppContext = createContext<AppContextValue | null>(null);

export function AppProvider({ children }: PropsWithChildren) {
  const system = useColorScheme();
  const [ready, setReady] = useState(false);
  const [language, setLanguageState] = useState<Language>('ru');
  const [themeMode, setThemeModeState] = useState<ThemeMode>('system');
  const [favorites, setFavorites] = useState<string[]>([]);
  const [introSeen, setIntroSeen] = useState(true);
  const [token, setToken] = useState<string | null>(null);
  const [user, setUser] = useState<StaffUser | null>(null);
  const [controlMode, setControlMode] = useState<ControlMode>('client');

  useEffect(() => {
    void (async () => {
      const [savedLanguage, savedTheme, savedFavorites, savedIntro, savedToken] = await Promise.all([
        storageGet(LANGUAGE_KEY), storageGet(THEME_KEY), storageGet(FAVORITES_KEY), storageGet(INTRO_KEY), storageGet(TOKEN_KEY),
      ]);
      if (savedLanguage === 'ru' || savedLanguage === 'uz') setLanguageState(savedLanguage);
      if (savedTheme === 'system' || savedTheme === 'light' || savedTheme === 'dark') setThemeModeState(savedTheme);
      if (savedFavorites) { try { setFavorites(JSON.parse(savedFavorites)); } catch {} }
      setIntroSeen(savedIntro !== null);
      if (savedToken) {
        setToken(savedToken);
        try { setUser(await getMe(savedToken)); } catch { await storageDelete(TOKEN_KEY); setToken(null); }
      }
      setReady(true);
    })();
  }, []);

  const resolvedTheme = themeMode === 'system' ? (system === 'dark' ? 'dark' : 'light') : themeMode;

  const setLanguage = useCallback((value: Language) => {
    setLanguageState(value); void storageSet(LANGUAGE_KEY, value);
  }, []);

  const setThemeMode = useCallback((value: ThemeMode) => {
    setThemeModeState(value);
    void storageSet(THEME_KEY, value);
  }, []);

  const toggleFavorite = useCallback((slug: string) => {
    setFavorites((current) => {
      const next = current.includes(slug) ? current.filter((item) => item !== slug) : [...current, slug];
      void storageSet(FAVORITES_KEY, JSON.stringify(next));
      return next;
    });
  }, []);

  const markIntroSeen = useCallback(() => { setIntroSeen(true); void storageSet(INTRO_KEY, '1'); }, []);

  const login = useCallback(async (email: string, password: string) => {
    const result = await loginStaff(email, password);
    setToken(result.session.token); setUser(result.user); setControlMode('control');
    await storageSet(TOKEN_KEY, result.session.token);
  }, []);

  const logout = useCallback(async () => {
    if (token) { try { await logoutStaff(token); } catch {} }
    setToken(null); setUser(null); setControlMode('client'); await storageDelete(TOKEN_KEY);
  }, [token]);

  const refreshMe = useCallback(async () => {
    if (!token) return;
    try { setUser(await getMe(token)); } catch { await logout(); }
  }, [logout, token]);

  const value = useMemo<AppContextValue>(() => ({
    ready, language, setLanguage, themeMode, setThemeMode, resolvedTheme, favorites, toggleFavorite,
    isFavorite: (slug: string) => favorites.includes(slug), introSeen, markIntroSeen, token, user, controlMode,
    setControlMode, login, logout, refreshMe,
  }), [controlMode, favorites, introSeen, language, login, logout, markIntroSeen, ready, refreshMe, resolvedTheme, setLanguage, setThemeMode, themeMode, token, toggleFavorite, user]);

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() {
  const value = useContext(AppContext);
  if (!value) throw new Error('useApp must be used inside AppProvider');
  return value;
}
