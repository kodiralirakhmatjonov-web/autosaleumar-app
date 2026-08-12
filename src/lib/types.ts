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
  engineText: string | null;
  shortDescriptionRu: string;
  shortDescriptionUz: string;
  coverUrl: string | null;
  variants?: CatalogVariant[];
}

export interface CatalogResponse {
  success?: boolean;
  cars?: CatalogCar[];
  error?: string;
}
