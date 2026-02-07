# ConsMas Mobile App — Data Model + Driver Flow

This document describes how the Flutter driver app should map the Daily Trip Manifest fields to backend data, and how the app flows from trip start to completion. Fields created by the admin/dispatcher should be **pre‑populated** on the driver side (read‑only unless noted).

Base API URL (dev): `http://localhost:3000`

All requests require:
- `Authorization: Bearer <JWT>`
- `Accept: application/json`

---

## Data Model Mapping

### Section A: General Trip Information (Trip)
**Source:** `GET /trips/:id`

| Manifest Field | Backend Field | Notes |
|---|---|---|
| Trip Date | `trip_date` | Admin‑set, read‑only |
| Truck Reg. No. | `truck_reg_no` | Auto from vehicle, read‑only |
| Driver Name | `driver.name` | From assigned driver, read‑only |
| Driver Contact | `driver_contact` or `driver.phone_number` | Use `driver_contact` if present; fallback to user phone |
| Truck Type / Capacity | `vehicle.truck_type_capacity` | From vehicle, read‑only |
| Odometer Reading (Start) | `start_odometer_km` | Captured by driver via odometer endpoint |
| Road Expense Disbursed | `road_expense_disbursed` | Admin‑set |
| Road Expense Payment Ref | `road_expense_reference` | Admin‑set |

### Section B: Delivery Details
**Source:** `GET /trips/:id` (single stop) or `/trips/:id/stops` (multi‑dropoff)

| Manifest Field | Backend Field | Notes |
|---|---|---|
| Client Name | `client_name` | Admin‑set |
| Waybill No. | `waybill_number` (synced with `reference_code`) | Admin‑set |
| Destination | `destination` | Admin‑set or per‑stop |
| Delivery Address | `delivery_address` | Admin‑set or per‑stop |
| Tonnage/Load | `tonnage_load` | Admin‑set or per‑stop |
| Estimated Departure Time | `estimated_departure_time` | Admin‑set |
| Estimated Arrival Time | `estimated_arrival_time` | Admin‑set |
| Customer Contact | `customer_contact_name`, `customer_contact_phone` | Admin‑set |
| Special Instructions | `special_instructions` | Admin‑set |

**Multi‑dropoff:**
- Use `TripStop` entries from `GET /trips/:id/stops`.
- Each stop has its own `destination`, `delivery_address`, `tonnage_load`, `waybill_number`, and contact info.

### Section C: Delivery Completion & Return
**Driver‑captured for each stop or single destination.**

| Manifest Field | Backend Field | Notes |
|---|---|---|
| Arrival Time at Site | `arrival_time_at_site` | Single‑dropoff on Trip; multi‑dropoff on TripStop |
| Client Rep Signature & Stamp | `client_rep_signature` (Trip attachment) | Upload endpoint pending |
| POD Type | `pod_type` | Trip or TripStop (`photo`, `e_signature`, `manual`) |
| Waybill Returned? | `waybill_returned` | Trip or TripStop |
| Notes/Incidents | `notes_incidents` | Trip or TripStop |

### Section D: Fuel Refilling
**Driver‑captured (end of trip).**

| Manifest Field | Backend Field | Notes |
|---|---|---|
| Odometer Reading (End) | `end_odometer_km` | Captured via odometer end endpoint |
| Fuel Station Used | `fuel_station_used` | Trip |
| Fuel Payment Mode | `fuel_payment_mode` | Trip (`cash`, `card`, `credit`) |
| Fuel Litres Filled | `fuel_litres_filled` | Trip |
| Fuel Receipt No. | `fuel_receipt_no` | Trip |
| Proof of Fuelling | `proof_of_fuelling` attachment | Upload endpoint pending |

### Section E: Post‑Trip
**Driver + supervisor signatures.**

| Manifest Field | Backend Field | Notes |
|---|---|---|
| Return Time | `return_time` | Trip |
| Vehicle Condition Post‑Trip | `vehicle_condition_post_trip` | Trip (`good`, `requires_service`, `damaged`) |
| Post‑Trip Inspector Name | `post_trip_inspector_name` | Trip |
| Inspector Signature | `inspector_signature` attachment | Upload endpoint pending |
| Security Signature | `security_signature` attachment | Upload endpoint pending |
| Driver Signature | `driver_signature` attachment | Upload endpoint pending |

---

## Driver Flow (Mobile)

### 1) Login
- `POST /auth/login`
- Store JWT from `Authorization` header

### 2) Trip List
- `GET /trips`
- Driver sees assigned trips only

### 3) Trip Detail (Pre‑populated Fields)
- `GET /trips/:id`
- `GET /trips/:id/stops` (if multi‑dropoff)
- All admin‑entered data is read‑only

### 4) Pre‑Trip Inspection
- `POST /trips/:id/pre_trip`
- Required checklist + odometer photo
- If `pre_trip.waybill_number` is sent, backend updates trip waybill

### 5) Start Odometer (Required before en_route)
- `POST /trips/:id/odometer/start` (multipart)

### 6) Start Trip + GPS Tracking
- Update status: `POST /trips/:id/status` → `en_route`
- Periodically send location pings:
  - `POST /trips/:id/locations`
- Backend computes distance using Google Roads API

### 7) Delivery Completion (Single or Multi‑Drop)
- For single destination: update Trip fields (`arrival_time_at_site`, `pod_type`, `notes_incidents`) via `PATCH /trips/:id`
- For multi‑dropoff: update each stop via `PATCH /trips/:id/stops/:stop_id`
- Upload evidence photos via `POST /trips/:id/evidence`

### 8) Fuel Refilling + End Odometer
- `POST /trips/:id/odometer/end` (multipart)
- Update fuel fields on Trip via `PATCH /trips/:id`

### 9) Post‑Trip Sign‑offs
- Update Trip fields (`return_time`, `vehicle_condition_post_trip`, `post_trip_inspector_name`) via `PATCH /trips/:id`
- Signature uploads pending endpoints

### 10) Complete Trip
- `POST /trips/:id/status` → `completed`

---

## Notes for Flutter Implementation

- Treat admin‑entered fields as read‑only.
- Use `vehicle.truck_type_capacity` for truck capacity display.
- Use `trip.distance_km` to display distance traveled.
- For multi‑dropoff, render each stop as a separate delivery card with its own waybill and tonnage.

---

If you want upload endpoints for signatures/fuelling photos, I can add them next.
