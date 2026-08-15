import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

async function webGet(key: string): Promise<string | null> {
  try { return (globalThis as any).localStorage?.getItem(key) ?? null; } catch { return null; }
}
async function webSet(key: string, value: string): Promise<void> {
  try { (globalThis as any).localStorage?.setItem(key, value); } catch {}
}
async function webDelete(key: string): Promise<void> {
  try { (globalThis as any).localStorage?.removeItem(key); } catch {}
}

export async function storageGet(key: string): Promise<string | null> {
  if (Platform.OS === 'web') return webGet(key);
  try { return await SecureStore.getItemAsync(key); } catch { return null; }
}

export async function storageSet(key: string, value: string): Promise<void> {
  if (Platform.OS === 'web') return webSet(key, value);
  try { await SecureStore.setItemAsync(key, value); } catch {}
}

export async function storageDelete(key: string): Promise<void> {
  if (Platform.OS === 'web') return webDelete(key);
  try { await SecureStore.deleteItemAsync(key); } catch {}
}
