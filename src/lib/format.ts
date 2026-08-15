import type { CarStatus, CatalogCar, Language } from './types';

export function formatPrice(car: Pick<CatalogCar, 'priceOnRequest' | 'price' | 'currency'>, language: Language = 'ru'): string {
  if (car.priceOnRequest || car.price == null) return language === 'ru' ? 'Цена по запросу' : 'Narx so‘rov bo‘yicha';
  const value = new Intl.NumberFormat(language === 'ru' ? 'ru-RU' : 'uz-UZ', { maximumFractionDigits: 0 }).format(car.price);
  if (car.currency === 'USD') return `${value} $`;
  if (car.currency === 'EUR') return `${value} €`;
  return `${value} сум`;
}

export function statusLabel(status: CarStatus, language: Language = 'ru'): string {
  const ru: Record<CarStatus, string> = { in_stock: 'В наличии', in_showroom: 'В шоуруме', in_transit: 'В пути', made_to_order: 'Под заказ', reserved: 'Резерв', sold: 'Продан', hidden: 'Скрыт' };
  const uz: Record<CarStatus, string> = { in_stock: 'Mavjud', in_showroom: 'Shourumda', in_transit: 'Yo‘lda', made_to_order: 'Buyurtma', reserved: 'Rezerv', sold: 'Sotilgan', hidden: 'Yashirin' };
  return (language === 'ru' ? ru : uz)[status];
}

export function firstPhoto(car: CatalogCar): string | null {
  if (car.coverUrl) return car.coverUrl;
  for (const variant of car.variants ?? []) {
    const photo = variant.photos?.find((item) => item.isCover) ?? variant.photos?.[0];
    if (photo?.url) return photo.url;
  }
  return null;
}

export function allExteriorPhotos(car: CatalogCar): string[] {
  const urls: string[] = [];
  if (car.coverUrl) urls.push(car.coverUrl);
  for (const variant of car.variants ?? []) for (const photo of variant.photos ?? []) if (!urls.includes(photo.url)) urls.push(photo.url);
  return urls;
}

export function allInteriorPhotos(car: CatalogCar): string[] {
  const urls: string[] = [];
  for (const variant of car.variants ?? []) for (const photo of variant.interiorPhotos ?? []) if (!urls.includes(photo.url)) urls.push(photo.url);
  return urls;
}

export function allDetailPhotos(car: CatalogCar): string[] {
  const urls: string[] = [];
  for (const variant of car.variants ?? []) for (const photo of variant.detailPhotos ?? []) if (!urls.includes(photo.url)) urls.push(photo.url);
  return urls;
}
