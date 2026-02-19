# Phase 4 UI Prompts (Fuel Anomaly + Analytics)

## Admin Dashboard Prompt
Implement a Fuel Analytics module using Phase 4 APIs.

- Fuel transactions page:
  - vehicle-scoped logs (`GET /api/v1/vehicles/:vehicle_id/fuel_logs`)
  - global logs (`GET /api/v1/fuel_logs`)
  - create entries (`POST /api/v1/vehicles/:vehicle_id/fuel_logs`, `POST /api/v1/trips/:trip_id/fuel_logs`).
- Anomaly center:
  - list analysis records (`GET /api/v1/fuel/analysis`)
  - unresolved anomalies board (`GET /api/v1/fuel/anomalies`)
  - investigation workflow (`PATCH /api/v1/fuel/analysis/:id/investigate`).
- Trend analytics:
  - vehicle trend (`GET /api/v1/fuel/analysis/vehicle/:vehicle_id`)
  - driver trend (`GET /api/v1/fuel/analysis/driver/:driver_id`).
- Fleet fuel report:
  - `GET /api/v1/reports/fuel`
  - cards: total liters, total cost, avg cost/L, anomaly count, estimated waste, best/worst performers.

## Mobile Prompt (Driver)
Implement fuel logging and efficiency awareness for driver app.

- Trip fueling capture:
  - submit fuel logs linked to trip (`POST /api/v1/trips/:trip_id/fuel_logs`).
- Vehicle fueling capture:
  - submit off-trip fueling (`POST /api/v1/vehicles/:vehicle_id/fuel_logs`).
- Driver insights page:
  - fetch driver trend (`GET /api/v1/fuel/analysis/driver/:driver_id`) if role allows.
- UX:
  - mark full-tank fills clearly (toggle),
  - validate liters/cost/odometer before submit,
  - show last submissions and sync status.
