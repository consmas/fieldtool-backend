# Phase 1 UI Prompts (Admin Dashboard + Driver Mobile)

## Admin Dashboard Prompt
Implement a **Maintenance & Work Orders** module for ConsMas Admin Dashboard, integrated with the new Phase 1 APIs.

Requirements:
- Add a top-level menu: `Maintenance`.
- Build pages/tabs:
  - `Due Maintenance` (uses `GET /api/v1/maintenance/due`, filters: priority, vehicle, overdue-only).
  - `Work Orders` (uses `GET /api/v1/work_orders`, supports filter/sort/pagination; columns: WO number, vehicle, type, status, priority, assigned, scheduled date, actual cost).
  - `Work Order Details` (uses `GET /api/v1/work_orders/:id` with full timeline, comments, parts, costs, downtime).
  - `Vendors` (CRUD via `/api/v1/maintenance/vendors`).
  - `Vehicle Documents` (per-vehicle list/upload/edit via `/api/v1/vehicles/:vehicle_id/documents`; expiring board via `/api/v1/documents/expiring`).
  - `Maintenance Reports` (uses `/api/v1/reports/maintenance` and `/api/v1/reports/vehicles/:id/maintenance_history`).
- Support actions:
  - Create/update work order.
  - Status transition (`PATCH /api/v1/work_orders/:id/status`) with transition guard.
  - Add/edit/delete parts.
  - Add comments.
  - Create schedule and apply schedule templates (`POST /api/v1/maintenance_schedules/templates`).
- KPI cards:
  - open work orders by priority,
  - overdue count,
  - vehicles in maintenance,
  - monthly and quarterly spend,
  - avg completion hours.
- Add visual urgency indicators:
  - red = overdue/critical,
  - amber = due soon/high,
  - green = healthy.
- Ensure responsive layout (desktop + tablet), fast table filtering, and empty/error/loading states.

## Driver Mobile App Prompt
Implement a **Driver Maintenance Awareness** section in the ConsMas driver app using Phase 1 APIs.

Requirements:
- Add a `Maintenance` tab with:
  - `My Vehicle Status` card: next due maintenance, overdue flag, days/km to due.
  - `My Vehicle Documents` list: document type, expiry, status badge (active/expiring/expired).
  - `Work Orders for My Vehicle` timeline: WO number, title, status, scheduled date, notes.
- Trip completion flow:
  - After trip completion sync, show a non-blocking banner if maintenance is due soon/overdue.
- Document UX:
  - Show expiry countdown and alert banner for expired/expiring documents.
- Work order UX:
  - Read-only for drivers unless role allows comments; if enabled, allow adding comment to WO.
- Reliability:
  - Cache last successful maintenance snapshot offline.
  - Retry on poor network.
- Notification hooks:
  - Support in-app rendering of maintenance-related alerts (`maintenance.due_soon`, `maintenance.overdue`, `maintenance.work_order_created`, `maintenance.work_order_completed`).

Notes:
- Respect role-based access.
- Keep API error handling explicit and user-friendly.
