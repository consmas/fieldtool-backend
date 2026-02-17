# ConsMas Mobile Screen Spec

Base URL: `https://ftapi.consmas.com`

Auth header for protected routes:
- `Authorization: Bearer <JWT>`
- `Accept: application/json`

## 1. Login Screen
`POST /auth/login`

Request:
```json
{
  "user": {
    "email": "driver@consmas.com",
    "password": "password"
  }
}
```

Response `200` (token in response header `Authorization`):
```json
{
  "user": {
    "id": 3,
    "email": "driver@consmas.com",
    "name": "Driver",
    "role": "driver"
  }
}
```

## 2. Trip List Screen
`GET /trips`

Response `200`:
```json
[
  {
    "id": 2,
    "reference_code": "TW0001",
    "status": "assigned",
    "destination": "Tema",
    "distance_km": "12.345",
    "driver": {
      "id": 3,
      "email": "driver@consmas.com",
      "name": "Driver",
      "role": "driver"
    },
    "vehicle": {
      "id": 1,
      "name": "SHACMAN 1",
      "license_plate": "GT-1296-26"
    }
  }
]
```

## 3. Trip Detail Screen
`GET /trips/:id`

Response `200`:
```json
{
  "id": 2,
  "reference_code": "TW0001",
  "status": "en_route",
  "waybill_number": "TW0001",
  "trip_date": "2026-02-09",
  "truck_reg_no": "GT-1296-26",
  "driver_contact": "0557495005",
  "destination": "Tema",
  "delivery_address": "Depot A",
  "tonnage_load": "50 tons",
  "distance_km": "80.123",
  "latest_location": {
    "id": 88,
    "lat": 5.6037,
    "lng": -0.1870,
    "speed": 22.3,
    "heading": 135.0,
    "recorded_at": "2026-02-09T10:00:00Z"
  },
  "client_rep_signature_url": null,
  "proof_of_fuelling_url": null,
  "inspector_signature_url": "https://ftapi.consmas.com/rails/active_storage/blobs/redirect/...",
  "security_signature_url": "https://ftapi.consmas.com/rails/active_storage/blobs/redirect/...",
  "driver_signature_url": "https://ftapi.consmas.com/rails/active_storage/blobs/redirect/..."
}
```

## 4. Stops Screen (Multi-Drop)
`GET /trips/:id/stops`

Response `200`:
```json
[
  {
    "id": 10,
    "trip_id": 2,
    "sequence": 1,
    "destination": "Tema",
    "delivery_address": "Depot A",
    "tonnage_load": "20 tons",
    "waybill_number": "TW0001-A",
    "customer_contact_name": "Kwame",
    "customer_contact_phone": "+233000000000",
    "pod_type": "photo",
    "waybill_returned": false,
    "notes_incidents": null
  }
]
```

## 5. Pre-Trip Checklist Screen
`POST /trips/:id/pre_trip` (multipart)

Required form fields:
- `pre_trip[odometer_value_km]`
- `pre_trip[odometer_photo]`
- `pre_trip[brakes]`
- `pre_trip[tyres]`
- `pre_trip[lights]`
- `pre_trip[mirrors]`
- `pre_trip[horn]`
- `pre_trip[fuel_sufficient]`
- `pre_trip[accepted]`
- `pre_trip[accepted_at]`

Optional:
- `pre_trip[odometer_captured_at]`
- `pre_trip[odometer_lat]`
- `pre_trip[odometer_lng]`
- `pre_trip[inspector_signature]`
- `pre_trip[inspector_photo]`

Response `200/201`:
```json
{
  "id": 1,
  "trip_id": 2,
  "odometer_value_km": "1000.0",
  "accepted": true,
  "inspection_verification_status": "pending",
  "odometer_photo_attached": true,
  "inspector_signature_attached": true,
  "inspector_photo_attached": true,
  "odometer_photo_url": "https://ftapi.consmas.com/rails/active_storage/blobs/redirect/...",
  "inspector_signature_url": "https://ftapi.consmas.com/rails/active_storage/blobs/redirect/...",
  "inspector_photo_url": "https://ftapi.consmas.com/rails/active_storage/blobs/redirect/..."
}
```

## 6. Load Details Screen
`PATCH /trips/:id/pre_trip` (multipart)

Fields:
- `pre_trip[load_area_ready]`
- `pre_trip[load_status]` (`full|partial`)
- `pre_trip[load_secured]`
- `pre_trip[load_note]`
- `pre_trip[load_photo]`
- `pre_trip[waybill_number]`
- `pre_trip[waybill_photo]`
- `pre_trip[assistant_name]`
- `pre_trip[assistant_phone]`
- `pre_trip[fuel_level]`

Response `200`: same shape as pre-trip payload.

## 7. Set Status Loaded
`POST /trips/:id/status`

Request:
```json
{ "status": "loaded" }
```

Response `200`:
```json
{
  "id": 2,
  "status": "loaded"
}
```

## 8. Start Trip (Slide)
`POST /trips/:id/status`

Request:
```json
{ "status": "en_route" }
```

Response `200`:
```json
{
  "id": 2,
  "status": "en_route"
}
```

## 9. Location Tracking (Background)
`POST /trips/:id/locations`

Request:
```json
{
  "location": {
    "lat": 5.72519,
    "lng": 0.01479,
    "speed": 20.5,
    "heading": 90.0,
    "recorded_at": "2026-02-09T10:15:00Z"
  }
}
```

Response `201`:
```json
{
  "id": 120,
  "trip_id": 2,
  "lat": 5.72519,
  "lng": 0.01479,
  "speed": 20.5,
  "heading": 90.0,
  "recorded_at": "2026-02-09T10:15:00Z"
}
```

Latest:
- `GET /trips/:id/locations/latest`

## 10. Evidence Upload Screen
`POST /trips/:id/evidence` (multipart)

Required:
- `evidence[kind]` (`before_loading|after_loading|en_route|arrival|offloading`)
- `evidence[photo]`

Optional:
- `evidence[recorded_at]`
- `evidence[note]`
- `evidence[lat]`
- `evidence[lng]`

Response `201`:
```json
{
  "id": 5,
  "trip_id": 2,
  "kind": "arrival",
  "note": "Arrived at site",
  "photo_attached": true,
  "photo_url": "https://ftapi.consmas.com/rails/active_storage/blobs/redirect/..."
}
```

## 11. Stop Completion Screen (Multi-Drop)
`PATCH /trips/:id/stops/:stop_id`

Request:
```json
{
  "stop": {
    "arrival_time_at_site": "10:30",
    "pod_type": "photo",
    "waybill_returned": true,
    "notes_incidents": "Delivered"
  }
}
```

Response `200`:
```json
{
  "id": 10,
  "trip_id": 2,
  "pod_type": "photo",
  "waybill_returned": true,
  "notes_incidents": "Delivered"
}
```

## 12. Delivery Completion Screen (Single Destination)
`PATCH /trips/:id`

Request:
```json
{
  "trip": {
    "arrival_time_at_site": "10:30",
    "pod_type": "photo",
    "waybill_returned": true,
    "notes_incidents": "Delivered"
  }
}
```

Response `200`: trip payload.

## 13. Attachments Screen (Signatures/Fuel Proof)
`PATCH /trips/:id/attachments` (multipart)

Optional fields:
- `attachments[client_rep_signature]`
- `attachments[proof_of_fuelling]`
- `attachments[inspector_signature]`
- `attachments[security_signature]`
- `attachments[driver_signature]`

Response `200`:
```json
{
  "trip_id": 2,
  "client_rep_signature_attached": true,
  "proof_of_fuelling_attached": true,
  "inspector_signature_attached": true,
  "security_signature_attached": true,
  "driver_signature_attached": true,
  "client_rep_signature_url": "https://ftapi.consmas.com/rails/active_storage/blobs/redirect/...",
  "proof_of_fuelling_url": "https://ftapi.consmas.com/rails/active_storage/blobs/redirect/...",
  "inspector_signature_url": "https://ftapi.consmas.com/rails/active_storage/blobs/redirect/...",
  "security_signature_url": "https://ftapi.consmas.com/rails/active_storage/blobs/redirect/...",
  "driver_signature_url": "https://ftapi.consmas.com/rails/active_storage/blobs/redirect/..."
}
```

## 14. End Odometer Screen
`POST /trips/:id/odometer/end` (multipart)

Required:
- `odometer[value_km]`
- `odometer[photo]`

Optional:
- `odometer[captured_at]`
- `odometer[note]`
- `odometer[lat]`
- `odometer[lng]`

Response `200`:
```json
{
  "trip_id": 2,
  "end_odometer_km": "1200.0",
  "end_odometer_captured_at": "2026-02-09T11:00:00Z",
  "end_odometer_photo_attached": true,
  "end_odometer_photo_url": "https://ftapi.consmas.com/rails/active_storage/blobs/redirect/..."
}
```

## 15. Fuel Refill Screen (Actual Fuel)
`PATCH /trips/:id`

Request:
```json
{
  "trip": {
    "fuel_station_used": "Westport",
    "fuel_payment_mode": "cash",
    "fuel_litres_filled": "120.0",
    "fuel_receipt_no": "REC-001"
  }
}
```

Response `200`: trip payload.

## 16. Post-Trip Screen
`PATCH /trips/:id`

Request:
```json
{
  "trip": {
    "return_time": "13:05",
    "vehicle_condition_post_trip": "good",
    "post_trip_inspector_name": "Klenam"
  }
}
```

Response `200`: trip payload.

## 17. End Trip (Slide)
`POST /trips/:id/status`

Request:
```json
{ "status": "completed" }
```

Response `200`:
```json
{
  "id": 2,
  "status": "completed",
  "completed_at": "2026-02-09T13:10:00Z"
}
```

## 18. Sync/Retry Rules
- Queue failed writes locally (`status`, `uploads`, `locations`).
- Replay order:
  1. status changes
  2. media uploads
  3. location pings
- Always refresh with:
  - `GET /trips/:id`
  - `GET /trips/:id/pre_trip`
- Use server URLs directly for image rendering.
