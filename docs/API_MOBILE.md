# ConsMas Fieldtool API (Flutter Mobile)

Base URL (dev): `http://localhost:3000`

All endpoints return JSON. Unless noted, requests require:
- Header: `Authorization: Bearer <JWT>`
- Header: `Accept: application/json`
- Header: `Content-Type: application/json`

## Auth

### POST /auth/login
Request body:
```json
{
  "user": {
    "email": "admin@example.com",
    "password": "password"
  }
}
```
Response body:
```json
{
  "user": {
    "id": 1,
    "email": "admin@example.com",
    "name": "Admin",
    "role": "admin"
  }
}
```
JWT is returned in **response header**:
```
Authorization: Bearer <token>
```

### DELETE /auth/logout
Headers: `Authorization: Bearer <token>`
Response: `200 OK`

## Trips

### GET /trips
Optional query: `?status=assigned`
Response (list):
```json
[
  {
    "id": 1,
    "reference_code": "WB-123",
    "status": "assigned",
    "pickup_location": "A",
    "dropoff_location": "B",
    "pickup_notes": null,
    "dropoff_notes": null,
    "material_description": "Gravel",
    "waybill_number": "WB-123",
    "scheduled_pickup_at": "2026-02-06T09:00:00Z",
    "scheduled_dropoff_at": "2026-02-06T11:00:00Z",
    "driver": { "id": 2, "email": "driver@example.com", "name": "Driver", "role": "driver" },
    "dispatcher_id": 1,
    "truck": { "id": 3, "name": "Truck 12", "kind": "truck", "license_plate": "ABC123" },
    "trailer": { "id": 4, "name": "Trailer A", "kind": "trailer", "license_plate": "TRL456" },
    "start_odometer_km": null,
    "end_odometer_km": null,
    "start_odometer_captured_at": null,
    "end_odometer_captured_at": null,
    "start_odometer_captured_by_id": null,
    "end_odometer_captured_by_id": null,
    "start_odometer_note": null,
    "end_odometer_note": null,
    "start_odometer_lat": null,
    "start_odometer_lng": null,
    "end_odometer_lat": null,
    "end_odometer_lng": null,
    "start_odometer_photo_attached": false,
    "end_odometer_photo_attached": false,
    "status_changed_at": null,
    "completed_at": null,
    "cancelled_at": null
  }
]
```

### GET /trips/:id
Response (show) includes latest location + event timeline:
```json
{
  "id": 1,
  "reference_code": "WB-123",
  "status": "assigned",
  "pickup_location": "A",
  "dropoff_location": "B",
  "pickup_notes": null,
  "dropoff_notes": null,
  "material_description": "Gravel",
  "waybill_number": "WB-123",
  "scheduled_pickup_at": "2026-02-06T09:00:00Z",
  "scheduled_dropoff_at": "2026-02-06T11:00:00Z",
  "driver": { "id": 2, "email": "driver@example.com", "name": "Driver", "role": "driver" },
  "dispatcher_id": 1,
  "truck": { "id": 3, "name": "Truck 12", "kind": "truck", "license_plate": "ABC123" },
  "trailer": { "id": 4, "name": "Trailer A", "kind": "trailer", "license_plate": "TRL456" },
  "start_odometer_km": null,
  "end_odometer_km": null,
  "start_odometer_captured_at": null,
  "end_odometer_captured_at": null,
  "start_odometer_captured_by_id": null,
  "end_odometer_captured_by_id": null,
  "start_odometer_note": null,
  "end_odometer_note": null,
  "start_odometer_lat": null,
  "start_odometer_lng": null,
  "end_odometer_lat": null,
  "end_odometer_lng": null,
  "start_odometer_photo_attached": false,
  "end_odometer_photo_attached": false,
  "status_changed_at": null,
  "completed_at": null,
  "cancelled_at": null,
  "latest_location": {
    "id": 9,
    "lat": 40.1,
    "lng": -74.1,
    "speed": 10.5,
    "heading": 180.0,
    "recorded_at": "2026-02-06T12:00:00Z"
  },
  "events": [
    {
      "id": 1,
      "event_type": "trip_created",
      "message": "Trip created",
      "data": { "status": "assigned" },
      "created_by_id": 1,
      "created_at": "2026-02-06T10:00:00Z"
    }
  ]
}
```

### POST /trips
Request body (nest under `trip`):
```json
{
  "trip": {
    "reference_code": "WB-123",
    "driver_id": 2,
    "dispatcher_id": 1,
    "truck_id": 3,
    "trailer_id": 4,
    "pickup_location": "A",
    "dropoff_location": "B",
    "pickup_notes": "Call on arrival",
    "dropoff_notes": null,
    "material_description": "Gravel",
    "waybill_number": "WB-123",
    "scheduled_pickup_at": "2026-02-06T09:00:00Z",
    "scheduled_dropoff_at": "2026-02-06T11:00:00Z"
  }
}
```
Response: same shape as `GET /trips/:id` without `events` and `latest_location`.

Note: `reference_code` and `waybill_number` are kept in sync. If you send one, the backend will auto-fill the other. If you send both, they must match.

### PATCH /trips/:id
Request body: same nesting as create (under `trip`).

### DELETE /trips/:id
Response: `204 No Content`

### POST /trips/:id/status
Advance status with enforcement rules.
Request body:
```json
{ "status": "assigned" }
```
Valid flow: `draft -> assigned -> loaded -> en_route -> arrived -> offloaded -> completed` (or `cancelled`).
Gating rules:
- `en_route` requires start odometer value + photo
- `completed` requires end odometer value + photo, and end >= start

### POST /trips/:id/locations
Record a GPS ping.
Request body:
```json
{
  "location": {
    "lat": 40.1,
    "lng": -74.1,
    "speed": 10.5,
    "heading": 180.0,
    "recorded_at": "2026-02-06T12:00:00Z"
  }
}
```
Response:
```json
{
  "id": 9,
  "trip_id": 1,
  "lat": 40.1,
  "lng": -74.1,
  "speed": 10.5,
  "heading": 180.0,
  "recorded_at": "2026-02-06T12:00:00Z"
}
```

### GET /trips/:id/locations/latest
Response: same shape as create, or `404` if none.

### POST /trips/:id/evidence (multipart/form-data)
Required fields:
- `evidence[kind]`: `before_loading | after_loading | en_route | arrival | offloading`
- `evidence[photo]`: file
Optional:
- `evidence[recorded_at]` (ISO timestamp)
- `evidence[note]`, `evidence[lat]`, `evidence[lng]`
Response:
```json
{
  "id": 1,
  "trip_id": 1,
  "kind": "before_loading",
  "note": "Loaded",
  "lat": 40.1,
  "lng": -74.1,
  "recorded_at": "2026-02-06T12:00:00Z",
  "uploaded_by_id": 2,
  "photo_attached": true
}
```

### POST /trips/:id/odometer/start (multipart/form-data)
Required fields:
- `odometer[value_km]`
- `odometer[photo]`
Optional:
- `odometer[captured_at]`, `odometer[note]`, `odometer[lat]`, `odometer[lng]`
Response:
```json
{
  "trip_id": 1,
  "start_odometer_km": "12345.6",
  "start_odometer_captured_at": "2026-02-06T12:00:00Z",
  "start_odometer_captured_by_id": 2,
  "start_odometer_note": "",
  "start_odometer_lat": 40.1,
  "start_odometer_lng": -74.1,
  "start_odometer_photo_attached": true
}
```

### POST /trips/:id/odometer/end (multipart/form-data)
Required fields:
- `odometer[value_km]`
- `odometer[photo]`
Optional:
- `odometer[captured_at]`, `odometer[note]`, `odometer[lat]`, `odometer[lng]`
Response:
```json
{
  "trip_id": 1,
  "end_odometer_km": "12400.0",
  "end_odometer_captured_at": "2026-02-06T14:00:00Z",
  "end_odometer_captured_by_id": 2,
  "end_odometer_note": "",
  "end_odometer_lat": 40.2,
  "end_odometer_lng": -74.2,
  "end_odometer_photo_attached": true
}
```

## Pre-Trip Inspection (Driver)

### GET /trips/:id/pre_trip
Response:
```json
{
  "id": 1,
  "trip_id": 1,
  "captured_by_id": 2,
  "odometer_value_km": "12345.6",
  "odometer_captured_at": "2026-02-06T12:00:00Z",
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
  "accepted_at": "2026-02-06T12:05:00Z",
  "waybill_number": "WB-123",
  "assistant_name": "Helper",
  "assistant_phone": "+233000000000",
  "fuel_level": "3/4",
  "odometer_photo_attached": true,
  "load_photo_attached": true,
  "waybill_photo_attached": false,
  "created_at": "2026-02-06T12:06:00Z",
  "updated_at": "2026-02-06T12:06:00Z"
}
```

### POST /trips/:id/pre_trip (multipart/form-data)
Required fields:
- `pre_trip[odometer_value_km]`
- `pre_trip[odometer_photo]` (file)
- `pre_trip[brakes]` (true/false)
- `pre_trip[tyres]` (true/false)
- `pre_trip[lights]` (true/false)
- `pre_trip[mirrors]` (true/false)
- `pre_trip[horn]` (true/false)
- `pre_trip[fuel_sufficient]` (true/false)
- `pre_trip[load_area_ready]` (true/false)
- `pre_trip[load_status]` (`full` or `partial`)
- `pre_trip[load_secured]` (true/false)
- `pre_trip[accepted]` (true/false)
Optional:
- `pre_trip[odometer_captured_at]`, `pre_trip[odometer_lat]`, `pre_trip[odometer_lng]`
- `pre_trip[load_note]`, `pre_trip[load_photo]` (file)
- `pre_trip[accepted_at]`
- `pre_trip[waybill_number]`, `pre_trip[waybill_photo]` (file) (if provided, updates trip `waybill_number` / `reference_code`)
- `pre_trip[assistant_name]`, `pre_trip[assistant_phone]`, `pre_trip[fuel_level]`
Response: same shape as `GET /trips/:id/pre_trip`

### PATCH /trips/:id/pre_trip (multipart/form-data)
Same fields as create. Response: same shape as `GET /trips/:id/pre_trip`.

## Users (Admin/Dispatcher/Supervisor only)

### GET /users
Response:
```json
[
  { "id": 1, "email": "admin@example.com", "name": "Admin", "role": "admin" }
]
```

### GET /users/:id
Response:
```json
{ "id": 1, "email": "admin@example.com", "name": "Admin", "role": "admin" }
```

### POST /users
Request body (nest under `user`):
```json
{
  "user": {
    "email": "driver@example.com",
    "password": "password",
    "password_confirmation": "password",
    "name": "Driver",
    "role": "driver"
  }
}
```
Response: same shape as `GET /users/:id`

### PATCH /users/:id
Request body:
```json
{ "user": { "name": "New Name", "role": "dispatcher" } }
```

### DELETE /users/:id
Response: `204 No Content`

## Vehicles

### GET /vehicles
Response:
```json
[
  { "id": 3, "name": "Truck 12", "kind": "truck", "license_plate": "ABC123", "vin": null, "notes": null, "active": true }
]
```

### GET /vehicles/:id
Response:
```json
{ "id": 3, "name": "Truck 12", "kind": "truck", "license_plate": "ABC123", "vin": null, "notes": null, "active": true }
```

### POST /vehicles
Request body (nest under `vehicle`):
```json
{
  "vehicle": {
    "name": "Truck 12",
    "kind": "truck",
    "license_plate": "ABC123",
    "vin": "VIN123",
    "notes": "Assigned to Team A",
    "active": true
  }
}
```

### PATCH /vehicles/:id
Request body:
```json
{ "vehicle": { "active": false } }
```

### DELETE /vehicles/:id
Response: `204 No Content`

## Errors

- `401 Unauthorized`: missing/invalid JWT
- `403 Forbidden`: role not permitted
- `404 Not Found`: resource missing
- `422 Unprocessable Entity`: validation errors

Error response shape:
```json
{ "error": ["message"] }
```

## Roles & Permissions (summary)
- `admin/dispatcher/supervisor`: manage trips, users, vehicles
- `driver`: can view own trips, upload evidence, submit locations, capture odometer, change own trip status
