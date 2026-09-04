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
    c.updated_at
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

function proxyURL(origin, mediaID) {
  return `${origin}/v1/media/${encodeURIComponent(String(mediaID))}`;
}

function toCar(row, mediaRows, origin) {
  const urls = mediaRows.map((item) => proxyURL(origin, item.id));
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
    coverUrl: urls[0] || null,
    images: urls,
    updatedAt: row.updated_at,
  };
}

async function listCars(env, origin) {
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
      SELECT *
      FROM car_media
      WHERE media_type = 'image'
        AND car_id IN (${placeholders})
      ORDER BY car_id ASC, is_cover DESC, sort_order ASC, id ASC
    `).bind(...ids).all();

  const byCar = new Map();
  for (const item of mediaResult.results || []) {
    const carID = Number(item.car_id);
    if (!Number.isFinite(carID) || item.id == null) continue;
    const bucket = byCar.get(carID) || [];
    bucket.push(item);
    byCar.set(carID, bucket);
  }

  return rows.map((row) => toCar(row, byCar.get(Number(row.id)) || [], origin));
}

function mediaBindings(env) {
  return Object.entries(env)
    .filter(([key, value]) => /^MEDIA_\d+$/.test(key) && value && typeof value.get === "function")
    .sort(([a], [b]) => Number(a.slice(6)) - Number(b.slice(6)))
    .map(([, value]) => value);
}

function decodeSafe(value) {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

function addKeyVariant(set, raw) {
  if (typeof raw !== "string") return;
  let value = raw.trim();
  if (!value) return;

  const push = (candidate) => {
    if (typeof candidate !== "string") return;
    let item = decodeSafe(candidate.trim()).replace(/^\/+/, "");
    if (!item) return;
    set.add(item);
  };

  push(value);

  if (/^https?:\/\//i.test(value)) {
    try {
      const url = new URL(value);
      const pathname = url.pathname || "";
      push(pathname);
      const segments = pathname.split("/").filter(Boolean);
      if (segments.length > 1) push(segments.slice(1).join("/"));
      if (segments.length > 2) push(segments.slice(2).join("/"));
    } catch {}
  }

  for (const prefix of ["media/", "r2/", "public/", "uploads/", "images/"]) {
    const normalized = value.replace(/^\/+/, "");
    if (normalized.startsWith(prefix)) push(normalized.slice(prefix.length));
  }
}

function candidateKeys(row) {
  const keys = new Set();
  const fields = [
    "object_key",
    "objectKey",
    "r2_key",
    "r2Key",
    "storage_key",
    "storageKey",
    "file_key",
    "fileKey",
    "key",
    "path",
    "public_url",
    "publicUrl",
    "url",
  ];
  for (const field of fields) addKeyVariant(keys, row?.[field]);
  return [...keys];
}

function contentTypeFromName(name) {
  const lower = String(name || "").toLowerCase();
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".webp")) return "image/webp";
  if (lower.endsWith(".gif")) return "image/gif";
  if (lower.endsWith(".avif")) return "image/avif";
  if (lower.endsWith(".heic")) return "image/heic";
  return "image/jpeg";
}

async function responseFromR2(object, key, request) {
  const headers = new Headers();
  if (object.httpMetadata?.contentType) headers.set("content-type", object.httpMetadata.contentType);
  else headers.set("content-type", contentTypeFromName(key));
  if (object.httpEtag) headers.set("etag", object.httpEtag);
  headers.set("cache-control", "public, max-age=31536000, immutable");
  headers.set("accept-ranges", "bytes");

  if (request.method === "HEAD") return new Response(null, { status: 200, headers });
  return new Response(object.body, { status: 200, headers });
}

async function serveMedia(request, env, mediaID) {
  const id = Number(mediaID);
  if (!Number.isInteger(id) || id <= 0) return json({ success: false, error: "Invalid media id" }, 400);

  const row = await env.DB.prepare(`
      SELECT *
      FROM car_media
      WHERE id = ?1
        AND media_type = 'image'
      LIMIT 1
    `).bind(id).first();

  if (!row) return json({ success: false, error: "Media not found" }, 404);

  const publicURL = row.public_url || row.publicUrl || row.url;
  if (typeof publicURL === "string" && /^https:\/\//i.test(publicURL.trim())) {
    try {
      const upstream = await fetch(publicURL.trim(), {
        headers: { accept: "image/avif,image/webp,image/*,*/*;q=0.8" },
        redirect: "follow",
      });
      const type = upstream.headers.get("content-type") || "";
      if (upstream.ok && type.toLowerCase().startsWith("image/")) {
        const headers = new Headers(upstream.headers);
        headers.set("cache-control", "public, max-age=31536000, immutable");
        if (request.method === "HEAD") return new Response(null, { status: 200, headers });
        return new Response(upstream.body, { status: 200, headers });
      }
    } catch {}
  }

  const keys = candidateKeys(row);
  const bindings = mediaBindings(env);

  for (const key of keys) {
    for (const bucket of bindings) {
      try {
        const object = await bucket.get(key);
        if (object) return responseFromR2(object, key, request);
      } catch {}
    }
  }

  return json(
    {
      success: false,
      error: "Media object not found in bound R2 buckets",
      mediaId: id,
      keyCandidates: keys.length,
      bucketBindings: bindings.length,
    },
    404,
  );
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: { allow: "GET, HEAD, OPTIONS" } });
    }

    if (!["GET", "HEAD"].includes(request.method)) {
      return json({ success: false, error: "Method not allowed" }, 405, { allow: "GET, HEAD, OPTIONS" });
    }
    if (!env.DB) return json({ success: false, error: "D1 binding DB is missing" }, 500);

    if (url.pathname === "/health" || url.pathname === "/v1/health") {
      return json({
        success: true,
        service: "autosaleumar-app-api",
        r2Bindings: mediaBindings(env).length,
      });
    }

    if (url.pathname === "/v1/cars") {
      try {
        const cars = await listCars(env, url.origin);
        return json({ success: true, total: cars.length, cars });
      } catch (error) {
        console.error("ASU app catalog failed", error);
        return json({ success: false, error: "Catalog unavailable" }, 500);
      }
    }

    const match = url.pathname.match(/^\/v1\/media\/(\d+)$/);
    if (match) {
      try {
        return await serveMedia(request, env, match[1]);
      } catch (error) {
        console.error("ASU media proxy failed", error);
        return json({ success: false, error: "Media unavailable" }, 500);
      }
    }

    return json({ success: false, error: "Not found" }, 404);
  },
};
