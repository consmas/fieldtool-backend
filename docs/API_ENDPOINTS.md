# ConsMas API Endpoints (Current)

Base URL (dev): `http://localhost:3000`

All requests (except login) require:
- `Authorization: Bearer <JWT>`
- `Accept: application/json`

## Auth
- `POST /auth/login`
- `DELETE /auth/logout`

## Trips
- `GET /trips`
- `GET /trips/:id`
- `POST /trips`
- `PATCH /trips/:id`
- `DELETE /trips/:id`

### Status
- `POST /trips/:id/status`

### Locations
- `POST /trips/:id/locations`
- `GET /trips/:id/locations/latest`

### Evidence
- `POST /trips/:id/evidence` (multipart)
  - Response:
```json
{
  "id": 1,
  "trip_id": 1,
  "kind": "before_loading",
  "note": "Loaded",
  "lat": 40.1,
  "lng": -74.1,
  "recorded_at": "2026-02-08T12:00:00Z",
  "uploaded_by_id": 2,
  "photo_attached": true,
  "photo_url": "http://localhost:3000/rails/active_storage/blobs/..."
}
```

### Odometer
- `POST /trips/:id/odometer/start` (multipart)
- `POST /trips/:id/odometer/end` (multipart)
  - Response (start):
```json
{
  "trip_id": 1,
  "start_odometer_km": "12345.6",
  "start_odometer_captured_at": "2026-02-08T12:00:00Z",
  "start_odometer_captured_by_id": 2,
  "start_odometer_note": null,
  "start_odometer_lat": 40.1,
  "start_odometer_lng": -74.1,
  "start_odometer_photo_attached": true,
  "start_odometer_photo_url": "http://localhost:3000/rails/active_storage/blobs/..."
}
```
  - Response (end):
```json
{
  "trip_id": 1,
  "end_odometer_km": "12400.0",
  "end_odometer_captured_at": "2026-02-08T14:00:00Z",
  "end_odometer_captured_by_id": 2,
  "end_odometer_note": null,
  "end_odometer_lat": 40.2,
  "end_odometer_lng": -74.2,
  "end_odometer_photo_attached": true,
  "end_odometer_photo_url": "http://localhost:3000/rails/active_storage/blobs/..."
}
```

### Pre‑Trip Inspection
- `GET /trips/:id/pre_trip`
- `POST /trips/:id/pre_trip` (multipart, upsert)
- `PATCH /trips/:id/pre_trip` (multipart)
  - Notes:
    - Initial `POST` can omit load fields; they can be sent later via `PATCH`.
    - New optional uploads: `pre_trip[inspector_signature]`, `pre_trip[inspector_photo]`.
  - Response (create/update):
```json
{
  "id": 1,
  "trip_id": 1,
  "captured_by_id": 2,
  "odometer_value_km": "12345.6",
  "odometer_captured_at": "2026-02-08T12:00:00Z",
  "odometer_lat": 40.1,
  "odometer_lng": -74.1,
  "brakes": true,
  "tyres": true,
  "lights": true,
  "mirrors": true,
  "horn": true,
  "fuel_sufficient": true,
  "load_area_ready": true,
  "load_status": "full",
  "load_secured": true,
  "load_note": "Load checked",
  "accepted": true,
  "accepted_at": "2026-02-08T12:05:00Z",
  "waybill_number": "WB-123",
  "assistant_name": "Helper",
  "assistant_phone": "+233000000000",
  "fuel_level": "3/4",
  "odometer_photo_attached": true,
  "load_photo_attached": true,
  "waybill_photo_attached": false,
  "inspector_signature_attached": true,
  "inspector_photo_attached": true,
  "odometer_photo_url": "http://localhost:3000/rails/active_storage/blobs/...",
  "load_photo_url": "http://localhost:3000/rails/active_storage/blobs/...",
  "waybill_photo_url": null,
  "inspector_signature_url": "http://localhost:3000/rails/active_storage/blobs/...",
  "inspector_photo_url": "http://localhost:3000/rails/active_storage/blobs/...",
  "created_at": "2026-02-08T12:06:00Z",
  "updated_at": "2026-02-08T12:06:00Z"
}
```

### Multi‑Dropoff Stops
- `GET /trips/:id/stops`
- `POST /trips/:id/stops`
- `PATCH /trips/:id/stops/:id`
- `DELETE /trips/:id/stops/:id`

### Trip Attachments (Signatures/Fuel Proof)
- `PATCH /trips/:id/attachments` (multipart)
  - `attachments[client_rep_signature]`
  - `attachments[proof_of_fuelling]`
  - `attachments[inspector_signature]`
  - `attachments[security_signature]`
  - `attachments[driver_signature]`
  - Response:
```json
{
  "trip_id": 1,
  "client_rep_signature_attached": true,
  "proof_of_fuelling_attached": true,
  "inspector_signature_attached": false,
  "security_signature_attached": false,
  "driver_signature_attached": true,
  "client_rep_signature_url": "http://localhost:3000/rails/active_storage/blobs/...",
  "proof_of_fuelling_url": "http://localhost:3000/rails/active_storage/blobs/...",
  "inspector_signature_url": null,
  "security_signature_url": null,
  "driver_signature_url": "http://localhost:3000/rails/active_storage/blobs/..."
}
```

## Users
- `GET /users`
- `GET /users/:id`
- `POST /users`
- `PATCH /users/:id`
- `DELETE /users/:id`

## Vehicles
- `GET /vehicles`
- `GET /vehicles/:id`
- `POST /vehicles`
- `PATCH /vehicles/:id`
- `DELETE /vehicles/:id`

## System
- `GET /up`
