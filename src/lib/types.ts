export type Language = 'ru' | 'uz';
export type ThemeMode = 'system' | 'light' | 'dark';
export type StaffRole = 'super_admin' | 'admin' | 'sales_manager';
export type StaffStatus = 'active' | 'blocked';
export type Currency = 'USD' | 'UZS' | 'EUR';
export type CarStatus = 'in_stock' | 'in_showroom' | 'in_transit' | 'made_to_order' | 'reserved' | 'sold' | 'hidden';

export interface CatalogPhoto {
  id: number;
  url: string;
  isCover: boolean;
  sortOrder: number;
}

export interface CatalogVariant {
  id: number;
  exteriorColorName: string | null;
  exteriorSwatch: string;
  interiorColorName: string | null;
  interiorSwatch: string;
  vin?: string | null;
  stockNumber?: string | null;
  quantity?: number;
  photos: CatalogPhoto[];
  interiorPhotos?: CatalogPhoto[];
  detailPhotos?: CatalogPhoto[];
}

export interface CatalogCar {
  id: number;
  slug: string;
  brand: string;
  model: string;
  year: number | null;
  trim: string | null;
  status: CarStatus;
  countryCode: string | null;
  arrivalDate: string | null;
  price: number | null;
  currency: Currency;
  priceOnRequest: boolean;
  mileageKm?: number | null;
  fuelType?: string | null;
  driveType?: string | null;
  transmission?: string | null;
  engineText: string | null;
  engineDisplacementL?: number | null;
  seats?: number | null;
  horsepowerHp?: number | null;
  torqueNm?: number | null;
  acceleration0100?: number | null;
  topSpeedKmh?: number | null;
  fuelConsumptionL100?: number | null;
  electricRangeKm?: number | null;
  shortDescriptionRu: string;
  shortDescriptionUz: string;
  descriptionRu?: string;
  descriptionUz?: string;
  instagramUrl?: string | null;
  isNew?: boolean;
  isNewArrival?: boolean;
  isFeatured?: boolean;
  coverUrl: string | null;
  variants?: CatalogVariant[];
}

export interface CatalogResponse {
  success?: boolean;
  cars?: CatalogCar[];
  car?: CatalogCar;
  error?: string;
}

export interface HomeMediaItem {
  key: string;
  url: string;
  size: number;
  uploadedAt: string | null;
  brand: string;
  model: string;
  price: number | null;
  currency: Currency;
  priceOnRequest: boolean;
  status: CarStatus;
}

export interface BrandMediaItem {
  key: string;
  url: string;
  size: number;
  uploadedAt?: string | null;
}

export interface StaffUser {
  id: number;
  email: string;
  fullName: string;
  phone?: string | null;
  role: StaffRole;
}

export interface StaffMember extends StaffUser {
  status: StaffStatus | string;
  createdBy?: number | null;
  createdAt?: string;
  updatedAt?: string;
  lastLoginAt?: string | null;
  isCurrentUser?: boolean;
}

export interface MobileSession {
  token: string;
  tokenType: 'Bearer';
  expiresAt: string;
}

export interface Visit {
  id: number;
  code: string;
  customerName: string;
  phone: string;
  visitDate: string;
  timeSlot: string;
  brand: string | null;
  carId: number | null;
  carLabel: string | null;
  note: string | null;
  status: 'new' | 'confirmed' | 'completed' | 'cancelled';
  createdAt: string;
  updatedAt: string;
}

export interface VehicleRequest {
  id: number;
  code: string;
  customerName: string;
  phone: string;
  contactChannel: 'whatsapp' | 'telegram' | 'phone';
  brand: string;
  model: string;
  trim: string | null;
  desiredYear: number | null;
  exteriorColor: string | null;
  interiorColor: string | null;
  importantOptions: string | null;
  maxBudget: number | null;
  currency: Currency;
  purchaseTiming: '7_days' | '30_days' | '90_days' | 'flexible';
  acceptInTransit: boolean;
  sourceUrl: string | null;
  note: string | null;
  status: 'new' | 'contacted' | 'sourcing' | 'offered' | 'completed' | 'cancelled';
  createdAt: string;
  updatedAt: string;
}

export interface AdminCar extends CatalogCar {
  vin?: string | null;
  stockNumber?: string | null;
  isPublic?: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface CarDraft {
  brand: string;
  model: string;
  year: string;
  trim: string;
  status: CarStatus;
  countryCode: string;
  arrivalDate: string;
  price: string;
  currency: Currency;
  priceOnRequest: boolean;
  isPublic: boolean;
  isFeatured: boolean;
  mileageKm: string;
  engineText: string;
  engineDisplacementL: string;
  fuelType: string;
  driveType: string;
  transmission: string;
  seats: string;
  horsepowerHp: string;
  torqueNm: string;
  acceleration0100: string;
  topSpeedKmh: string;
  fuelConsumptionL100: string;
  electricRangeKm: string;
  instagramUrl: string;
  shortDescriptionRu: string;
  shortDescriptionUz: string;
  descriptionRu: string;
  descriptionUz: string;
  exteriorColorName: string;
  exteriorSwatch: string;
  interiorColorName: string;
  interiorSwatch: string;
  vin: string;
  stockNumber: string;
  quantity: string;
  variantId?: number | null;
}
