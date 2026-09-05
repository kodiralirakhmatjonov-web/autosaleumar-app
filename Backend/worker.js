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
    st.exterior_swatch,
    v.interior_color_ru AS interior_color,
    st.interior_swatch,
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
  LEFT JOIN car_variant_style st ON st.variant_id = v.id
`;

function variantMediaURL(origin, mediaID) {
  return `${origin}/v1/variant-media/${encodeURIComponent(String(mediaID))}`;
}

function legacyMediaURL(origin, mediaID) {
  return `${origin}/v1/media/${encodeURIComponent(String(mediaID))}`;
}

function toPublicCar(row, images) {
  return {
    id: row.id,
    slug: row.slug,
    brand: row.brand,
    model: row.model,
    year: row.year,
    trim: row.trim,
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
    exteriorSwatch: row.exterior_swatch || null,
    interiorColor: row.interior_color,
    interiorSwatch: row.interior_swatch || null,
    shortDescriptionRu: row.short_description_ru,
    shortDescriptionUz: row.short_description_uz,
    descriptionRu: row.description_ru,
    descriptionUz: row.description_uz,
    isNew: row.is_new === 1,
    isNewArrival: row.is_new_arrival === 1,
    isPublic: row.is_public === 1,
    isFeatured: row.is_featured === 1,
    coverUrl: images[0] || null,
    images,
    updatedAt: row.updated_at,
  };
}

async function loadListMedia(env, carIDs, origin) {
  const byCar = new Map();
  if (!carIDs.length) return byCar;
  const placeholders = carIDs.map((_, index) => `?${index + 1}`).join(",");

  try {
    const result = await env.DB.prepare(`
      SELECT
        m.id, m.car_id, m.variant_id, m.object_key, m.public_url,
        m.photo_group, m.is_cover, m.sort_order,
        v.is_default, v.sort_order AS variant_sort
      FROM car_variant_media m
      INNER JOIN car_variants v ON v.id = m.variant_id
      WHERE m.car_id IN (${placeholders})
        AND m.photo_group = 'exterior'
        AND m.object_key NOT LIKE '%/detail/%'
      ORDER BY m.car_id ASC, v.is_default DESC, v.sort_order ASC, v.id ASC,
               m.is_cover DESC, m.sort_order ASC, m.id ASC
    `).bind(...carIDs).all();

    for (const item of result.results || []) {
      const carID = Number(item.car_id);
      if (!Number.isFinite(carID) || item.id == null) continue;
      const bucket = byCar.get(carID) || [];
      if (bucket.length < 12) bucket.push(variantMediaURL(origin, item.id));
      byCar.set(carID, bucket);
    }
  } catch (error) {
    console.warn("Normalized variant media lookup failed; trying legacy media", error);
  }

  const missing = carIDs.filter((id) => !(byCar.get(id)?.length));
  if (!missing.length) return byCar;

  try {
    const fallbackPlaceholders = missing.map((_, index) => `?${index + 1}`).join(",");
    const legacy = await env.DB.prepare(`
      SELECT id, car_id
      FROM car_media
      WHERE media_type = 'image'
        AND car_id IN (${fallbackPlaceholders})
      ORDER BY car_id ASC, is_cover DESC, sort_order ASC, id ASC
    `).bind(...missing).all();

    for (const item of legacy.results || []) {
      const carID = Number(item.car_id);
      if (!Number.isFinite(carID) || item.id == null) continue;
      const bucket = byCar.get(carID) || [];
      if (bucket.length < 12) bucket.push(legacyMediaURL(origin, item.id));
      byCar.set(carID, bucket);
    }
  } catch (error) {
    console.warn("Legacy media fallback lookup failed", error);
  }

  return byCar;
}

async function listCars(env, origin) {
  const list = await env.DB.prepare(`${CAR_SELECT}
    WHERE c.is_published = 1
      AND c.status != 'hidden'
    ORDER BY
      c.is_featured DESC,
      CASE c.status
        WHEN 'in_showroom' THEN 0
        WHEN 'in_stock' THEN 1
        WHEN 'in_transit' THEN 2
        WHEN 'made_to_order' THEN 3
        WHEN 'reserved' THEN 4
        WHEN 'sold' THEN 5
        ELSE 6
      END,
      c.updated_at DESC,
      c.id DESC
    LIMIT 100
  `).all();

  const rows = Array.isArray(list.results) ? list.results : [];
  if (!rows.length) return [];
  const ids = rows.map((row) => Number(row.id)).filter(Number.isFinite);
  const byCar = await loadListMedia(env, ids, origin);
  return rows.map((row) => toPublicCar(row, byCar.get(Number(row.id)) || []));
}

async function carDetailBySlug(env, origin, slug) {
  const row = await env.DB.prepare(`${CAR_SELECT}
    WHERE c.slug = ?1
      AND c.is_published = 1
      AND c.status != 'hidden'
    LIMIT 1
  `).bind(slug).first();

  if (!row) return null;

  const [variantResult, mediaResult, performance, links, weeklyViews] = await Promise.all([
    env.DB.prepare(`
      SELECT
        v.id,
        v.color_name_ru AS exterior_color_name,
        v.interior_color_ru AS interior_color_name,
        st.exterior_swatch,
        st.interior_swatch,
        v.is_default,
        v.sort_order
      FROM car_variants v
      LEFT JOIN car_variant_style st ON st.variant_id = v.id
      WHERE v.car_id = ?1
      ORDER BY v.is_default DESC, v.sort_order ASC, v.id ASC
    `).bind(row.id).all(),
    env.DB.prepare(`
      SELECT
        id, variant_id, object_key, public_url,
        CASE WHEN object_key LIKE '%/detail/%' THEN 'detail' ELSE photo_group END AS photo_group,
        is_cover, sort_order
      FROM car_variant_media
      WHERE car_id = ?1
      ORDER BY variant_id ASC, photo_group ASC, is_cover DESC, sort_order ASC, id ASC
    `).bind(row.id).all(),
    env.DB.prepare(`
      SELECT
        engine_displacement_l, horsepower_hp, torque_nm, acceleration_0_100_s,
        top_speed_kmh, fuel_consumption_l_100km, electric_range_km
      FROM car_performance
      WHERE car_id = ?1
      LIMIT 1
    `).bind(row.id).first(),
    env.DB.prepare(`
      SELECT instagram_url
      FROM car_links
      WHERE car_id = ?1
      LIMIT 1
    `).bind(row.id).first(),
    env.DB.prepare(`
      SELECT COALESCE(SUM(views), 0) AS total
      FROM car_view_daily
      WHERE car_id = ?1
        AND view_date >= date('now', '-6 days')
    `).bind(row.id).first().catch(() => ({ total: 0 })),
  ]);

  const mediaByVariant = new Map();
  for (const media of mediaResult.results || []) {
    const current = mediaByVariant.get(media.variant_id) || [];
    current.push(media);
    mediaByVariant.set(media.variant_id, current);
  }

  const variants = (variantResult.results || []).map((variant) => {
    const media = mediaByVariant.get(variant.id) || [];
    const mapPhotos = (group) => media
      .filter((item) => item.photo_group === group)
      .map((item) => ({
        id: item.id,
        url: variantMediaURL(origin, item.id),
        isCover: item.is_cover === 1,
        sortOrder: item.sort_order || 0,
      }));

    return {
      id: variant.id,
      exteriorColorName: variant.exterior_color_name,
      exteriorSwatch: variant.exterior_swatch || "#111214",
      interiorColorName: variant.interior_color_name,
      interiorSwatch: variant.interior_swatch || "#111214",
      photos: mapPhotos("exterior"),
      interiorPhotos: mapPhotos("interior"),
      detailPhotos: mapPhotos("detail"),
    };
  });

  let coverUrl = null;
  for (const variant of variants) {
    const cover = variant.photos.find((photo) => photo.isCover) || variant.photos[0];
    if (cover?.url) { coverUrl = cover.url; break; }
  }

  if (!coverUrl) {
    const fallback = await loadListMedia(env, [Number(row.id)], origin);
    coverUrl = fallback.get(Number(row.id))?.[0] || null;
  }

  return {
    ...toPublicCar(row, coverUrl ? [coverUrl] : []),
    coverUrl,
    weeklyViews: Number(weeklyViews?.total || 0),
    engineDisplacementL: performance?.engine_displacement_l ?? null,
    horsepowerHp: performance?.horsepower_hp ?? null,
    torqueNm: performance?.torque_nm ?? null,
    acceleration0100: performance?.acceleration_0_100_s ?? null,
    topSpeedKmh: performance?.top_speed_kmh ?? null,
    fuelConsumptionL100: performance?.fuel_consumption_l_100km ?? null,
    electricRangeKm: performance?.electric_range_km ?? null,
    instagramUrl: links?.instagram_url ?? null,
    variants,
  };
}

function mediaBindings(env) {
  return Object.entries(env)
    .filter(([key, value]) => /^MEDIA_\d+$/.test(key) && value && typeof value.get === "function")
    .sort(([a], [b]) => Number(a.slice(6)) - Number(b.slice(6)))
    .map(([, value]) => value);
}

function decodeSafe(value) {
  try { return decodeURIComponent(value); }
  catch { return value; }
}

function addKeyVariant(set, raw) {
  if (typeof raw !== "string") return;
  const value = raw.trim();
  if (!value) return;

  const push = (candidate) => {
    if (typeof candidate !== "string") return;
    const item = decodeSafe(candidate.trim()).replace(/^\/+/, "");
    if (item) set.add(item);
  };

  push(value);
  if (/^https?:\/\//i.test(value)) {
    try {
      const url = new URL(value);
      push(url.pathname || "");
      const segments = (url.pathname || "").split("/").filter(Boolean);
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
  for (const field of ["object_key", "objectKey", "r2_key", "r2Key", "storage_key", "storageKey", "file_key", "fileKey", "key", "path", "public_url", "publicUrl", "url"]) {
    addKeyVariant(keys, row?.[field]);
  }
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
  headers.set("x-content-type-options", "nosniff");
  if (request.method === "HEAD") return new Response(null, { status: 200, headers });
  return new Response(object.body, { status: 200, headers });
}

async function serveRowMedia(request, env, table, id) {
  if (!Number.isInteger(id) || id <= 0) return json({ success: false, error: "Invalid media id" }, 400);

  const row = await env.DB.prepare(`SELECT * FROM ${table} WHERE id = ?1 LIMIT 1`).bind(id).first();
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
        headers.set("x-content-type-options", "nosniff");
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

  return json({
    success: false,
    error: "Media object not found in bound R2 buckets",
    mediaId: id,
    keyCandidates: keys.length,
    bucketBindings: bindings.length,
  }, 404);
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
      return json({ success: true, service: "autosaleumar-app-api", r2Bindings: mediaBindings(env).length });
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

    const carMatch = url.pathname.match(/^\/v1\/cars\/([^/]+)$/);
    if (carMatch) {
      try {
        const slug = decodeSafe(carMatch[1]).trim();
        if (!slug || slug.length > 140) return json({ success: false, error: "Invalid slug" }, 400);
        const car = await carDetailBySlug(env, url.origin, slug);
        if (!car) return json({ success: false, error: "Car not found" }, 404);
        return json({ success: true, car });
      } catch (error) {
        console.error("ASU app detail failed", error);
        return json({ success: false, error: "Car detail unavailable" }, 500);
      }
    }

    const variantMediaMatch = url.pathname.match(/^\/v1\/variant-media\/(\d+)$/);
    if (variantMediaMatch) {
      try { return await serveRowMedia(request, env, "car_variant_media", Number(variantMediaMatch[1])); }
      catch (error) {
        console.error("ASU variant media proxy failed", error);
        return json({ success: false, error: "Media unavailable" }, 500);
      }
    }

    const legacyMediaMatch = url.pathname.match(/^\/v1\/media\/(\d+)$/);
    if (legacyMediaMatch) {
      try { return await serveRowMedia(request, env, "car_media", Number(legacyMediaMatch[1])); }
      catch (error) {
        console.error("ASU legacy media proxy failed", error);
        return json({ success: false, error: "Media unavailable" }, 500);
      }
    }

    return json({ success: false, error: "Not found" }, 404);
  },
};
