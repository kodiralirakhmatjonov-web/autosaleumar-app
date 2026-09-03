const json = (data, status = 200, extra = {}) =>
  new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": status === 200 ? "public, max-age=30, stale-while-revalidate=120" : "no-store",
      ...extra,
    },
  });

const CAR_SELECT = `
  SELECT
    c.id,
    c.slug,
    b.name AS brand,
    c.model,
    c.model_year AS year,
    c.trim,
    c.vin,
    c.stock_number,
    c.status,
    c.source_country AS country_code,
    c.arrival_date,
    c.price_amount AS price,
    c.price_currency AS currency,
    c.price_on_request,
    c.mileage_km,
    s.engine_name AS engine_text,
    s.fuel_type_ru AS fuel_type,
    s.drivetrain_ru AS drive_type,
    s.transmission_ru AS transmission,
    s.seats,
    v.color_name_ru AS exterior_color,
    v.interior_color_ru AS interior_color,
    c.short_description_ru,
    c.short_description_uz,
    c.description_ru,
    c.description_uz,
    c.is_new,
    c.is_new_arrival,
    c.is_published AS is_public,
    c.is_featured,
    c.updated_at,
    (
      SELECT cm.public_url
      FROM car_media cm
      WHERE cm.car_id = c.id
        AND cm.media_type = 'image'
      ORDER BY cm.is_cover DESC, cm.sort_order ASC, cm.id ASC
      LIMIT 1
    ) AS cover_url
  FROM cars c
  INNER JOIN brands b ON b.id = c.brand_id
  LEFT JOIN car_specs s ON s.car_id = c.id
  LEFT JOIN car_variants v ON v.id = (
    SELECT cv.id
    FROM car_variants cv
    WHERE cv.car_id = c.id
    ORDER BY cv.is_default DESC, cv.sort_order ASC, cv.id ASC
    LIMIT 1
  )
`;

function toCar(row, images) {
  return {
    id: row.id,
    slug: row.slug,
    brand: row.brand,
    model: row.model,
    year: row.year,
    trim: row.trim,
    vin: row.vin,
    stockNumber: row.stock_number,
    status: row.status,
    countryCode: row.country_code,
    arrivalDate: row.arrival_date,
    price: row.price,
    currency: row.currency || "USD",
    priceOnRequest: row.price_on_request === 1,
    mileageKm: row.mileage_km,
    engineText: row.engine_text,
    fuelType: row.fuel_type,
    driveType: row.drive_type,
    transmission: row.transmission,
    seats: row.seats,
    exteriorColor: row.exterior_color,
    interiorColor: row.interior_color,
    shortDescriptionRu: row.short_description_ru,
    shortDescriptionUz: row.short_description_uz,
    descriptionRu: row.description_ru,
    descriptionUz: row.description_uz,
    isNew: row.is_new === 1,
    isNewArrival: row.is_new_arrival === 1,
    isPublic: row.is_public === 1,
    isFeatured: row.is_featured === 1,
    coverUrl: row.cover_url,
    images: images.get(row.id) || (row.cover_url ? [row.cover_url] : []),
    updatedAt: row.updated_at,
  };
}

async function listCars(env) {
  const list = await env.DB.prepare(`${CAR_SELECT}
    WHERE c.is_published = 1
      AND c.status != 'hidden'
    ORDER BY
      CASE c.status
        WHEN 'in_showroom' THEN 0
        WHEN 'in_stock' THEN 1
        WHEN 'in_transit' THEN 2
        WHEN 'made_to_order' THEN 3
        WHEN 'reserved' THEN 4
        WHEN 'sold' THEN 5
        ELSE 6
      END,
      c.is_featured DESC,
      c.updated_at DESC,
      c.id DESC
    LIMIT 100
  `).all();

  const rows = Array.isArray(list.results) ? list.results : [];
  if (!rows.length) return [];

  const ids = rows.map((row) => Number(row.id)).filter(Number.isFinite);
  const placeholders = ids.map((_, index) => `?${index + 1}`).join(",");
  const mediaResult = await env.DB.prepare(`
      SELECT car_id, public_url
      FROM car_media
      WHERE media_type = 'image'
        AND car_id IN (${placeholders})
      ORDER BY car_id ASC, is_cover DESC, sort_order ASC, id ASC
    `).bind(...ids).all();

  const images = new Map();
  for (const item of mediaResult.results || []) {
    if (!item.public_url) continue;
    const carID = Number(item.car_id);
    const bucket = images.get(carID) || [];
    if (!bucket.includes(item.public_url)) bucket.push(item.public_url);
    images.set(carID, bucket);
  }

  return rows.map((row) => toCar(row, images));
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: { allow: "GET, OPTIONS" } });
    }

    if (request.method !== "GET") return json({ success: false, error: "Method not allowed" }, 405, { allow: "GET, OPTIONS" });
    if (!env.DB) return json({ success: false, error: "D1 binding DB is missing" }, 500);

    if (url.pathname === "/health" || url.pathname === "/v1/health") {
      return json({ success: true, service: "autosaleumar-app-api" });
    }

    if (url.pathname === "/v1/cars") {
      try {
        const cars = await listCars(env);
        return json({ success: true, total: cars.length, cars });
      } catch (error) {
        console.error("ASU app catalog failed", error);
        return json({ success: false, error: "Catalog unavailable" }, 500);
      }
    }

    return json({ success: false, error: "Not found" }, 404);
  },
};
