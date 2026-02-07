# ConsMas Admin/Dispatcher Panel Documentation

This document describes the admin/dispatcher UI flows and the API fields required for trip creation and management.

Base URL (dev): `http://localhost:3000`

All requests require:
- `Authorization: Bearer <JWT>`
- `Accept: application/json`
- `Content-Type: application/json`

## Roles

- **Admin / Dispatcher / Supervisor**: full trip management, users, vehicles
- **Driver**: view assigned trips, upload evidence, location pings, odometer, pre‑trip

## Trip Creation (Dispatcher)

### Required fields (minimum)
- `driver_id`
- `vehicle_id`

### Section B: Delivery Details (Dispatcher‑filled)
These map directly to `Trip` fields.

| Field (UI) | API Field | Type | Required | Example |
|---|---|---|---|---|
| Client Name | `client_name` | string | recommended | `Fabrimetal Ghana Ltd` |
| Waybill No. | `waybill_number` or `reference_code` | string | recommended | `WB-123` |
| Destination | `destination` | string | recommended | `Tema` |
| Delivery Address | `delivery_address` | string | optional | `DPS Ghana, Depot 3` |
| Tonnage/Load | `tonnage_load` | string | optional | `48 tons of rebar` |
| Customer Contact (Name) | `customer_contact_name` | string | optional | `Kwame Mensah` |
| Customer Contact (Phone) | `customer_contact_phone` | string | optional | `+233000000000` |
| Special Instructions | `special_instructions` | text | optional | `Unload with crane; site access at rear` |

> Note: `waybill_number` and `reference_code` are kept in sync by the backend. You can send either.

### Trip Create API
`POST /trips`

Request body:
```json
{
  "trip": {
    "driver_id": 3,
    "vehicle_id": 4,
    "client_name": "Fabrimetal Ghana Ltd",
    "waybill_number": "WB-123",
    "destination": "Tema",
    "delivery_address": "DPS Ghana, Depot 3",
    "tonnage_load": "48 tons of rebar",
    "customer_contact_name": "Kwame Mensah",
    "customer_contact_phone": "+233000000000",
    "special_instructions": "Unload with crane; site access at rear"
  }
}
```

Response: `200 OK` with the trip payload.

## Trip Update (Dispatcher)

`PATCH /trips/:id` accepts the same `trip` payload for updates, including Section B fields.

## Trip Status (Dispatcher)

- `POST /trips/:id/status` with `{ "status": "assigned" }` (or other next status)
- Enforced flow and gating as documented in `docs/API_MOBILE.md`

## Vehicles

- Create/Manage vehicles: `POST /vehicles`, `PATCH /vehicles/:id`
- `vehicle.license_plate` is used to auto‑populate `truck_reg_no` on trips.
- Maintain `vehicle.truck_type_capacity` here (e.g., `Articulated – 50 tons`).

## Users

- Create/Manage users: `POST /users`, `PATCH /users/:id`
- Include `phone_number` when adding or editing users.

## Notes for UI

- If a dispatcher enters a **Waybill No.**, it will also be stored as `reference_code`.
- Section B fields are editable prior to driver assignment and can be locked post‑assignment if desired (UI decision).

## Vehicle Page Notes

- Display `license_plate` as **Truck Reg. No.**.
- Allow editing `truck_type_capacity` for existing vehicles.
