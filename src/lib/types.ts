export type CarStatus =
  | 'in_stock'
  | 'in_showroom'
  | 'in_transit'
  | 'made_to_order'
  | 'reserved'
  | 'sold'
  | 'hidden';

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
  currency: 'USD' | 'UZS' | 'EUR';
  priceOnRequest: boolean;
  mileageKm?: number | null;
  fuelType?: string | null;
  driveType?: string | null;
  transmission?: string | null;
  engineText: string | null;
  seats?: number | null;
  exteriorColor?: string | null;
  interiorColor?: string | null;
  shortDescriptionRu: string;
  shortDescriptionUz: string;
  descriptionRu?: string;
  descriptionUz?: string;
  isNew?: boolean;
  isNewArrival?: boolean;
  isFeatured?: boolean;
  updatedAt?: string;
  coverUrl: string | null;
  engineDisplacementL?: number | null;
  horsepowerHp?: number | null;
  torqueNm?: number | null;
  acceleration0100?: number | null;
  topSpeedKmh?: number | null;
  fuelConsumptionL100?: number | null;
  electricRangeKm?: number | null;
  instagramUrl?: string | null;
  variants?: CatalogVariant[];
}

export interface CatalogResponse {
  success?: boolean;
  cars?: CatalogCar[];
  error?: string;
}
