import type {
  AdminCar,
  BrandMediaItem,
  CarDraft,
  CatalogCar,
  CatalogResponse,
  HomeMediaItem,
  MobileSession,
  StaffMember,
  StaffRole,
  StaffUser,
  VehicleRequest,
  Visit,
} from './types';

export const API_BASE_URL = process.env.EXPO_PUBLIC_API_BASE_URL?.replace(/\/$/, '') || 'https://autosaleumar.com';

export function absoluteMediaUrl(value: string | null | undefined): string | null {
  if (!value) return null;
  if (/^https?:\/\//i.test(value)) return value;
  return `${API_BASE_URL}${value.startsWith('/') ? '' : '/'}${value}`;
}

async function parseJson<T>(response: Response): Promise<T> {
  let payload: any = null;
  try { payload = await response.json(); } catch {}
  if (!response.ok || payload?.success === false) {
    throw new Error(payload?.error || `HTTP ${response.status}`);
  }
  return payload as T;
}

function authHeaders(token?: string | null, json = true): Record<string, string> {
  const headers: Record<string, string> = { Accept: 'application/json' };
  if (json) headers['Content-Type'] = 'application/json';
  if (token) headers.Authorization = `Bearer ${token}`;
  return headers;
}

export async function getCatalog(pageSize = 100): Promise<CatalogCar[]> {
  const response = await fetch(`${API_BASE_URL}/api/catalog?pageSize=${pageSize}`, { headers: { Accept: 'application/json' } });
  const payload = await parseJson<CatalogResponse>(response);
  return (payload.cars ?? []).filter((car) => car.status !== 'hidden');
}

export async function getCar(slug: string): Promise<CatalogCar> {
  const response = await fetch(`${API_BASE_URL}/api/catalog?slug=${encodeURIComponent(slug)}`, { headers: { Accept: 'application/json' } });
  const payload = await parseJson<CatalogResponse>(response);
  const car = payload.car ?? payload.cars?.[0];
  if (!car) throw new Error('Автомобиль не найден.');
  return car;
}

export async function getBrandMedia(brand: string): Promise<BrandMediaItem[]> {
  const response = await fetch(`${API_BASE_URL}/api/brand-media?brand=${encodeURIComponent(brand)}`, { headers: { Accept: 'application/json' } });
  const payload = await parseJson<{ success: boolean; images?: BrandMediaItem[] }>(response);
  return payload.images ?? [];
}

export async function getHomeMedia(): Promise<HomeMediaItem[]> {
  const response = await fetch(`${API_BASE_URL}/api/home-media`, { headers: { Accept: 'application/json' } });
  const payload = await parseJson<{ success: boolean; videos?: HomeMediaItem[] }>(response);
  return payload.videos ?? [];
}

export async function submitVisit(body: {
  customerName: string; phone: string; visitDate: string; timeSlot: string;
  brand?: string; carId?: number | null; carLabel?: string; note?: string;
}): Promise<Visit> {
  const response = await fetch(`${API_BASE_URL}/api/visits`, { method: 'POST', headers: authHeaders(null), body: JSON.stringify(body) });
  const payload = await parseJson<{ success: boolean; visit: Visit }>(response);
  return payload.visit;
}

export async function submitVehicleRequest(body: Record<string, unknown>): Promise<VehicleRequest> {
  const response = await fetch(`${API_BASE_URL}/api/vehicle-requests`, { method: 'POST', headers: authHeaders(null), body: JSON.stringify(body) });
  const payload = await parseJson<{ success: boolean; request: VehicleRequest }>(response);
  return payload.request;
}

export async function loginStaff(email: string, password: string): Promise<{ user: StaffUser; session: MobileSession }> {
  const response = await fetch(`${API_BASE_URL}/api/login`, {
    method: 'POST', headers: authHeaders(null), body: JSON.stringify({ email, password, client: 'mobile' }),
  });
  return parseJson(response);
}

export async function getMe(token: string): Promise<StaffUser> {
  const response = await fetch(`${API_BASE_URL}/api/me`, { headers: authHeaders(token, false) });
  const payload = await parseJson<{ success: boolean; user: StaffUser }>(response);
  return payload.user;
}

export async function logoutStaff(token: string): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/api/logout`, { method: 'POST', headers: authHeaders(token, false) });
  await parseJson(response);
}

export async function getAdminCars(token: string): Promise<AdminCar[]> {
  const response = await fetch(`${API_BASE_URL}/api/cars?pageSize=200`, { headers: authHeaders(token, false) });
  const payload = await parseJson<{ success: boolean; cars?: AdminCar[] }>(response);
  return payload.cars ?? [];
}

function num(value: string): number | null {
  if (!value.trim()) return null;
  const n = Number(value.replace(',', '.'));
  return Number.isFinite(n) ? n : null;
}

export function carDraftPayload(draft: CarDraft) {
  return {
    brand: draft.brand.trim(), model: draft.model.trim(), year: num(draft.year), trim: draft.trim.trim(), status: draft.status,
    countryCode: draft.countryCode.trim().toUpperCase(), arrivalDate: draft.arrivalDate.trim(), price: num(draft.price), currency: draft.currency,
    priceOnRequest: draft.priceOnRequest, mileageKm: num(draft.mileageKm), engineText: draft.engineText.trim(), engineDisplacementL: num(draft.engineDisplacementL), fuelType: draft.fuelType.trim(),
    driveType: draft.driveType.trim(), transmission: draft.transmission.trim() || 'automatic', seats: num(draft.seats), horsepowerHp: num(draft.horsepowerHp),
    torqueNm: num(draft.torqueNm), acceleration0100: num(draft.acceleration0100), topSpeedKmh: num(draft.topSpeedKmh), fuelConsumptionL100: num(draft.fuelConsumptionL100), electricRangeKm: num(draft.electricRangeKm), instagramUrl: draft.instagramUrl.trim(),
    shortDescriptionRu: draft.shortDescriptionRu.trim(), shortDescriptionUz: draft.shortDescriptionUz.trim(), descriptionRu: draft.descriptionRu.trim(),
    descriptionUz: draft.descriptionUz.trim(), isNew: (num(draft.mileageKm) ?? 0) === 0, isPublic: draft.isPublic, isFeatured: draft.isFeatured,
    variants: [{ ...(draft.variantId ? { id: draft.variantId } : {}), exteriorColorName: draft.exteriorColorName.trim() || null, exteriorSwatch: draft.exteriorSwatch || '#111214', interiorColorName: draft.interiorColorName.trim() || null,
      interiorSwatch: draft.interiorSwatch || '#111214', vin: draft.vin.trim() || null, stockNumber: draft.stockNumber.trim() || null, quantity: num(draft.quantity) ?? 1 }],
  };
}

export async function createAdminCar(token: string, draft: CarDraft): Promise<AdminCar> {
  const response = await fetch(`${API_BASE_URL}/api/cars`, { method: 'POST', headers: authHeaders(token), body: JSON.stringify(carDraftPayload(draft)) });
  const payload = await parseJson<{ success: boolean; car: AdminCar }>(response);
  return payload.car;
}


export async function updateAdminCar(token: string, id: number, draft: CarDraft): Promise<any> {
  const response = await fetch(`${API_BASE_URL}/api/car-detail`, { method: 'PATCH', headers: authHeaders(token), body: JSON.stringify({ id, ...carDraftPayload(draft) }) });
  const payload = await parseJson<{ success: boolean; car: any }>(response);
  return payload.car;
}

export async function quickUpdateCar(token: string, id: number, changes: Record<string, unknown>): Promise<AdminCar> {
  const response = await fetch(`${API_BASE_URL}/api/cars`, { method: 'PATCH', headers: authHeaders(token), body: JSON.stringify({ id, ...changes }) });
  const payload = await parseJson<{ success: boolean; car: AdminCar }>(response);
  return payload.car;
}

export async function getStaff(token: string): Promise<StaffMember[]> {
  const response = await fetch(`${API_BASE_URL}/api/staff`, { headers: authHeaders(token, false) });
  const payload = await parseJson<{ success: boolean; staff?: StaffMember[] }>(response);
  return payload.staff ?? [];
}

export async function createStaff(token: string, input: { fullName: string; email: string; phone: string; role: 'admin' | 'sales_manager' }) {
  const response = await fetch(`${API_BASE_URL}/api/staff`, { method: 'POST', headers: authHeaders(token), body: JSON.stringify(input) });
  return parseJson<{ success: boolean; staff: StaffMember; temporaryPassword: string }>(response);
}

export async function updateStaff(token: string, id: number, changes: { role?: StaffRole; status?: 'active' | 'blocked' }) {
  const response = await fetch(`${API_BASE_URL}/api/staff`, { method: 'POST', headers: authHeaders(token), body: JSON.stringify({ action: 'update', id, ...changes }) });
  return parseJson<{ success: boolean; staff: StaffMember }>(response);
}

export async function getVisits(token: string): Promise<Visit[]> {
  const response = await fetch(`${API_BASE_URL}/api/visits`, { headers: authHeaders(token, false) });
  const payload = await parseJson<{ success: boolean; visits?: Visit[] }>(response);
  return payload.visits ?? [];
}

export async function updateVisit(token: string, id: number, status: Visit['status']): Promise<Visit> {
  const response = await fetch(`${API_BASE_URL}/api/visits`, { method: 'PATCH', headers: authHeaders(token), body: JSON.stringify({ id, status }) });
  const payload = await parseJson<{ success: boolean; visit: Visit }>(response);
  return payload.visit;
}

export async function getVehicleRequests(token: string): Promise<VehicleRequest[]> {
  const response = await fetch(`${API_BASE_URL}/api/vehicle-requests`, { headers: authHeaders(token, false) });
  const payload = await parseJson<{ success: boolean; requests?: VehicleRequest[] }>(response);
  return payload.requests ?? [];
}

export async function updateVehicleRequest(token: string, id: number, status: VehicleRequest['status']): Promise<VehicleRequest> {
  const response = await fetch(`${API_BASE_URL}/api/vehicle-requests`, { method: 'PATCH', headers: authHeaders(token), body: JSON.stringify({ id, status }) });
  const payload = await parseJson<{ success: boolean; request: VehicleRequest }>(response);
  return payload.request;
}

export async function uploadBrandCover(token: string, brand: string, asset: { uri: string; name?: string | null; mimeType?: string | null }) {
  const form = new FormData();
  form.append('brand', brand);
  form.append('file', { uri: asset.uri, name: asset.name || 'cover.jpg', type: asset.mimeType || 'image/jpeg' } as any);
  const response = await fetch(`${API_BASE_URL}/api/brand-media`, { method: 'POST', headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' }, body: form });
  return parseJson(response);
}

export async function uploadHomeVideo(token: string, input: { asset: { uri: string; name?: string | null; mimeType?: string | null }; brand: string; model: string; price: string; status: string }) {
  const form = new FormData();
  form.append('brand', input.brand); form.append('model', input.model); form.append('price', input.price); form.append('currency', 'USD'); form.append('status', input.status); form.append('priceOnRequest', input.price.trim() ? '0' : '1');
  form.append('file', { uri: input.asset.uri, name: input.asset.name || 'hero.mp4', type: input.asset.mimeType || 'video/mp4' } as any);
  const response = await fetch(`${API_BASE_URL}/api/home-media`, { method: 'POST', headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' }, body: form });
  return parseJson(response);
}

export async function getAdminCarDetail(token: string, id: number): Promise<any> {
  const response = await fetch(`${API_BASE_URL}/api/car-detail?id=${id}`, { headers: authHeaders(token, false) });
  const payload = await parseJson<{ success: boolean; car: any }>(response);
  return payload.car;
}

export async function uploadCarPhoto(token: string, input: { carId: number; variantId: number; group: 'exterior' | 'interior' | 'detail'; isCover?: boolean; sortOrder?: number; asset: { uri: string; name?: string | null; mimeType?: string | null } }) {
  const form = new FormData();
  form.append('carId', String(input.carId)); form.append('variantId', String(input.variantId)); form.append('group', input.group);
  form.append('sortOrder', String(input.sortOrder ?? 0)); form.append('isCover', input.isCover ? '1' : '0');
  form.append('file', { uri: input.asset.uri, name: input.asset.name || 'photo.jpg', type: input.asset.mimeType || 'image/jpeg' } as any);
  const response = await fetch(`${API_BASE_URL}/api/car-media`, { method: 'POST', headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' }, body: form });
  return parseJson(response);
}

export async function deleteBrandCover(token: string, key: string) {
  const response = await fetch(`${API_BASE_URL}/api/brand-media?key=${encodeURIComponent(key)}`, { method: 'DELETE', headers: authHeaders(token, false) });
  return parseJson(response);
}

export async function deleteHomeVideo(token: string, key: string) {
  const response = await fetch(`${API_BASE_URL}/api/home-media?key=${encodeURIComponent(key)}`, { method: 'DELETE', headers: authHeaders(token, false) });
  return parseJson(response);
}
