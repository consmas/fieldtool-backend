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
  - Destination location fields supported in create/update and returned in list/detail:
    - `delivery_address`
    - `delivery_place_id`
    - `delivery_lat`
    - `delivery_lng`
    - `delivery_map_url`
    - `delivery_location_source` (`manual|google_autocomplete|shared_link|geolocation`)
    - `delivery_location_resolved_at`

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
    - New optional checklist payload:
      - `pre_trip[core_checklist]` (object) OR `pre_trip[core_checklist_json]` (JSON string)
      - Each item value can be `"pass"|"fail"|"na"` or `{ "status": "pass|fail|na", "note": "..." }`.
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
  "core_checklist": {
    "vehicle_exterior.lights_indicators_working": "pass",
    "engine.coolant_level_ok": {
      "status": "fail",
      "note": "Top up before departure"
    }
  },
  "core_checklist_template": [
    {
      "code": "vehicle_exterior.lights_indicators_working",
      "label": "Lights & indicators",
      "section": "vehicle_exterior",
      "severity_on_fail": "blocker"
    }
  ],
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

### Trip Chat (Driver <-> Dispatcher)
- `GET /trips/:id/chat`
  - Returns thread with messages (creates no data if thread does not yet exist).
- `POST /trips/:id/chat/messages`
  - Body:
```json
{
  "message": {
    "body": "Arrived at gate, waiting for clearance"
  }
}
```
  - Response `201`:
```json
{
  "id": 10,
  "chat_thread_id": 3,
  "sender_id": 2,
  "body": "Arrived at gate, waiting for clearance",
  "read_at": null,
  "created_at": "2026-02-18T10:30:00Z"
}
```
- `PATCH /trips/:id/chat/messages/:id`
  - Marks a received message as read (no-op for own message).
- `GET /chat/inbox`
  - Returns threads with unread counts for current user.

### General Chat (Users)
- `GET /chat/conversations`
  - Lists conversations for current user.
- `POST /chat/conversations`
  - Body:
```json
{
  "conversation": {
    "title": "Ops Coordination",
    "participant_ids": [2, 5]
  }
}
```
  - For 1-to-1 chats, existing direct conversation is reused.
- `GET /chat/conversations/:id`
  - Returns conversation details and messages.
- `PATCH /chat/conversations/:id/read`
  - Marks conversation as read for current user.
- `POST /chat/conversations/:conversation_id/messages`
  - Body:
```json
{
  "message": {
    "body": "Please share your ETA."
  }
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

## Logistics Manager

### Pre‑Trip Verification
- `PATCH /trips/:id/pre_trip/verify`
  - Body:
```json
{ "status": "approved", "note": "All checks passed" }
```
  - Response:
```json
{ "status": "approved" }
```

- `PATCH /trips/:id/pre_trip/confirm`
  - Response:
```json
{ "confirmed": true }
```

### Fuel Allocation
- `PATCH /trips/:id/fuel_allocation`
  - Body:
```json
{
  "fuel_allocation": {
    "fuel_allocated_litres": "120.0",
    "fuel_allocation_station": "Westport",
    "fuel_allocation_payment_mode": "cash",
    "fuel_allocation_reference": "FUEL-123",
    "fuel_allocation_note": "Allocate before departure"
  }
}
```

### Road Expense Payment
- `PATCH /trips/:id/road_expense`
  - Body:
```json
{
  "road_expense": {
    "road_expense_disbursed": "150.00",
    "road_expense_reference": "RV-221",
    "road_expense_payment_status": "paid",
    "road_expense_payment_method": "momo",
    "road_expense_payment_reference": "MOMO-REF-1",
    "road_expense_note": "Paid to driver"
  }
}
```

- `PATCH /trips/:id/road_expense/receipt` (multipart)
  - Field: `receipt` (file)

## System
- `GET /up`

## Expenses (Fleet Cost Ledger)
- `GET /expenses`
  - Filters: `date_from`, `date_to`, `category`, `status`, `trip_id`, `vehicle_id`, `driver_id`, `min_amount`, `max_amount`, `auto_generated`, `limit`, `offset`
- `POST /expenses`
- `PATCH /expenses/:id`
- `DELETE /expenses/:id` (soft delete)

### Workflow
- `POST /expenses/:id/submit`
- `POST /expenses/:id/approve`
- `POST /expenses/:id/reject` (requires `reason`)
- `POST /expenses/:id/mark-paid`

### Bulk
- `POST /expenses/bulk/approve`
- `POST /expenses/bulk/reject`
- `POST /expenses/bulk/mark-paid`
  - Body shape:
```json
{
  "ids": [1, 2, 3],
  "reason": "Only required for reject"
}
```

### Reporting
- `GET /expenses/summary`
  - Returns aggregate totals by category/status/vehicle/driver/trip.

### Automation
- `POST /expenses/automation/road-fee/sync`
  - Idempotently creates `road_fee` entries (`amount=100`, `currency=GHS`, `auto_rule_key=road_fee_en_route_v1`) for `en_route` trips missing one.
- `POST /expenses/fuel/recalculate`
  - Optional body:
```json
{
  "trip_ids": [1, 2],
  "price_per_liter": "14.38"
}
```
  - Uses trip liters: `fuel_litres_filled` fallback `fuel_allocated_litres`.

## Reporting
- `GET /reports/overview`
  - High-level fleet KPIs: trip counts, completion rate, distance, expense totals, cost per km.
- `GET /reports/trips`
  - Trip status breakdown, trip timelines, incidents, destination volume.
- `GET /reports/expenses`
  - Expense totals by category/status + daily trend and dimensions.
- `GET /reports/drivers`
  - Driver-level performance and expense totals.
- `GET /reports/vehicles`
  - Vehicle-level trips, distance, fuel liters, and maintenance/repair spend.

Common query params (where relevant):
- `date_from`, `date_to`
- `status`
- `category`
- `trip_id`, `vehicle_id`, `driver_id`
