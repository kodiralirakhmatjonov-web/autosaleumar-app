import type { CatalogCar, CatalogResponse } from './types';

const API_BASE_URL = process.env.EXPO_PUBLIC_API_BASE_URL?.replace(/\/$/, '') || 'https://autosaleumar.com';

export function absoluteMediaUrl(value: string | null | undefined): string | null {
  if (!value) return null;
  if (/^https?:\/\//i.test(value)) return value;
  return `${API_BASE_URL}${value.startsWith('/') ? '' : '/'}${value}`;
}

async function readJson<T>(response: Response): Promise<T> {
  const payload = (await response.json()) as T;
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return payload;
}

export async function getCatalog(pageSize = 100): Promise<CatalogCar[]> {
  const response = await fetch(`${API_BASE_URL}/api/catalog?pageSize=${pageSize}`, {
    headers: { Accept: 'application/json' },
  });
  const payload = await readJson<CatalogResponse>(response);
  if (!payload.success || !Array.isArray(payload.cars)) {
    throw new Error(payload.error || 'Catalog unavailable');
  }
  return payload.cars.filter((car) => car.status !== 'hidden');
}

export async function getCar(slug: string): Promise<CatalogCar> {
  const response = await fetch(`${API_BASE_URL}/api/catalog?slug=${encodeURIComponent(slug)}`, {
    headers: { Accept: 'application/json' },
  });
  const payload = await readJson<CatalogResponse & { car?: CatalogCar }>(response);
  const car = payload.car ?? payload.cars?.[0];
  if (!payload.success || !car) throw new Error(payload.error || 'Vehicle unavailable');
  return car;
}
