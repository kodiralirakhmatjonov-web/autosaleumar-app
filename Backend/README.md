# Auto Sale Umar app API

This Worker belongs to the **Auto Sale Umar app repository**. It does not modify or deploy the website repository.

It exposes only published, non-hidden cars from the existing Auto Sale Umar D1 database:

- `GET /v1/cars`
- `GET /v1/health`

The iOS client uses `https://app-api.autosaleumar.com/v1/cars`.

Deploy with the separate `deploy-app-api.yml` workflow supplied with this update. The workflow needs `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` in this app repository. `ASU_D1_DATABASE_ID` is optional; if omitted the workflow attempts to discover the unique D1 database containing the normalized `cars`, `brands`, and `car_media` tables.
