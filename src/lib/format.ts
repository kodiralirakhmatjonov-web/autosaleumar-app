import type { CatalogCar, CarStatus } from './types';

export function formatPrice(car: CatalogCar): string {
  if (car.priceOnRequest || car.price == null) return 'Цена по запросу';
  const locale = car.currency === 'UZS' ? 'uz-UZ' : 'en-US';
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency: car.currency,
    maximumFractionDigits: 0,
  }).format(car.price);
}

export function statusLabel(status: CarStatus): string {
  switch (status) {
    case 'in_showroom': return 'В шоуруме';
    case 'in_stock': return 'В наличии';
    case 'in_transit': return 'В пути';
    case 'made_to_order': return 'Под заказ';
    case 'reserved': return 'Зарезервирован';
    case 'sold': return 'Продан';
    default: return '';
  }
}
