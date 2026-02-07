# ConsMas Admin Panel (Next.js) — Comprehensive Flow

This document describes the end‑to‑end admin/dispatcher flows for the Next.js operations panel, including UI structure, key screens, and the API calls they trigger.

Base API URL (dev): `http://localhost:3000`

All requests (except login) require:
- `Authorization: Bearer <JWT>`
- `Accept: application/json`
- `Content-Type: application/json`

---

## 1) Auth + Roles

**Goal:** Login and enforce role-based access.

**Flow:**
1. User visits `/login`.
2. Submit credentials → `POST /auth/login`.
3. Store JWT (from `Authorization` response header) in memory or secure storage.
4. Route user based on role:
   - `admin/dispatcher/supervisor` → full dashboard
   - `driver` → deny or redirect to mobile (not for admin panel)

**API:**
- `POST /auth/login` with `{ user: { email, password } }`

---

## 2) Dashboard Overview

**Goal:** Provide at‑a‑glance operational status.

**Widgets (suggested):**
- Trips by status (draft/assigned/en_route/etc.) → `GET /trips` and aggregate client‑side
- Active drivers count → `GET /users` filter by role
- Vehicles available → `GET /vehicles` filter `active: true`
- Latest incidents/notes → from `GET /trips/:id` events (if needed)

---

## 3) Trips Module

### 3.1 Trip List
**Route:** `/trips`

**Filters:** status, date range, driver, vehicle, destination.

**API:**
- `GET /trips?status=assigned`

### 3.2 Trip Detail
**Route:** `/trips/:id`

**Tabs:**
- Overview (Section A + B summary)
- Status timeline (events)
- Evidence & photos
- Pre‑trip inspection
- GPS trail

**API:**
- `GET /trips/:id`
- `GET /trips/:id/pre_trip`
- `GET /trips/:id/locations/latest`

### 3.3 Create Trip (Dispatcher)
**Route:** `/trips/new`

**Required:** `driver_id`, `vehicle_id`

**Section A (General):**
- `trip_date`
- `vehicle_id` (auto‑populate `truck_reg_no` from vehicle)
- `driver_id`
- `driver_contact`
- `truck_type_capacity`
- `road_expense_disbursed`
- `road_expense_reference`

**Section B (Delivery Details):**
- `client_name`
- `waybill_number` (synced to `reference_code`)
- `destination`
- `delivery_address`
- `tonnage_load`
- `customer_contact_name`
- `customer_contact_phone`
- `special_instructions`

**API:**
- `POST /trips` with `trip` payload

### 3.4 Update Trip
**Route:** `/trips/:id/edit`

**API:**
- `PATCH /trips/:id` with `trip` payload

### 3.5 Status Updates
- Manual status update (dispatcher/admin): `POST /trips/:id/status`
- Enforced flow: `draft → assigned → loaded → en_route → arrived → offloaded → completed` or `cancelled`

---

## 4) Vehicles Module

**Route:** `/vehicles`

**Features:**
- List/search vehicles
- Create/edit vehicle

**API:**
- `GET /vehicles`
- `POST /vehicles`
- `PATCH /vehicles/:id`
- `DELETE /vehicles/:id`

---

## 5) Users Module

**Route:** `/users`

**Features:**
- Create drivers/dispatchers/supervisors
- Edit roles

**API:**
- `GET /users`
- `POST /users`
- `PATCH /users/:id`
- `DELETE /users/:id`

---

## 6) Live Tracking (Map)

**Route:** `/tracking`

**Flow:**
- List active trips
- Show last known location per trip
- Optional: polling every 15–30s

**API:**
- `GET /trips` (filter by status `en_route`)
- `GET /trips/:id/locations/latest`
Distance tracking:
- Backend computes distance from GPS pings (Google Roads API snapping).
- Use `trip.distance_km` and `trip.distance_computed_at`.

---

## 7) Evidence Review + Download

**Route:** `/trips/:id/evidence`

**Flow:**
- Display evidence list and images by `kind`
- If needed, show odometer photos and proof of delivery

**API:**
- Evidence is uploaded via `/trips/:id/evidence` (mobile), but admin panel fetches it via `GET /trips/:id` and/or an added endpoint if you want list separation.

---

## 8) Reports / Exports

**Route:** `/reports`

**Suggested exports:**
- Trips by date range
- Driver activity summary
- Vehicle usage report

**Current API:** not implemented. If you want, I can add:
- `GET /reports/trips?from=YYYY-MM-DD&to=YYYY-MM-DD`
- `GET /reports/vehicles`

---

## Data Field Mapping (Trip)

**Manifest fields (Section A–E)** are all stored on `Trip` and can be set by the dispatcher/admin:
- Section A: `trip_date`, `truck_reg_no`, `driver_contact`, `truck_type_capacity`, `road_expense_disbursed`, `road_expense_reference`
- Section B: `client_name`, `waybill_number`, `destination`, `delivery_address`, `tonnage_load`, `customer_contact_name`, `customer_contact_phone`, `special_instructions`
- Section C: `arrival_time_at_site`, `pod_type`, `waybill_returned`, `notes_incidents`
- Section D: `fuel_station_used`, `fuel_payment_mode`, `fuel_litres_filled`, `fuel_receipt_no`
- Section E: `return_time`, `vehicle_condition_post_trip`, `post_trip_inspector_name`

Multi‑dropoff:
- Use `TripStop` records to model each destination with its own waybill and tonnage.
- Endpoints: `/trips/:id/stops`

Attachments modeled on Trip (no upload endpoints yet):
- `client_rep_signature`, `proof_of_fuelling`, `inspector_signature`, `security_signature`, `driver_signature`

---

## Frontend Architecture Suggestions (Next.js)

- **Routes**
  - `/login`
  - `/dashboard`
  - `/trips`, `/trips/new`, `/trips/[id]`, `/trips/[id]/edit`
  - `/vehicles`
  - `/users`
  - `/tracking`
  - `/reports`

- **API Client**
  - Centralized Axios/fetch client that injects `Authorization` header
  - Extract JWT from login response header

- **State**
  - Keep user + token in memory or secure storage
  - Use SWR/React Query for caching and polling (tracking)

---

If you want a UI wireframe checklist or actual Next.js pages/components layout, say the word.
