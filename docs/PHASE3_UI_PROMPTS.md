# Phase 3 UI Prompts (Client Portal + Live Tracking)

## Client Web Portal Prompt
Implement a client-facing portal integrated with `/api/v1/client/*`.

- Auth:
  - login/logout + token persistence.
- Dashboard (`GET /api/v1/client/dashboard`):
  - active shipments, in-transit, delivered this month, outstanding balance, recent and upcoming shipments.
- Shipments:
  - list/filter page (`/api/v1/client/shipments`)
  - shipment detail (`/api/v1/client/shipments/:tracking_number`)
  - live tracking tab (`/api/v1/client/shipments/:tracking_number/track`)
  - events timeline (`/events`)
  - POD viewer (`/pod`)
  - feedback capture (`POST /feedback`)
- Invoices:
  - list and details (`/api/v1/client/invoices`)
  - billing summary (`/api/v1/client/billing/summary`)
- Profile:
  - company and user profile view (`/api/v1/client/profile`)
  - preferences update + password change.

## Mobile Tracking Prompt
Implement tracking screens for client app and shared links.

- Authenticated client app uses `/api/v1/client/*`.
- Public recipient tracking page uses `/api/v1/track/:tracking_link_token`.
- Show current shipment stage, timeline, and last known location.
- Hide sensitive internal data (full driver details, internal notes).
- Add clear fallback states: token expired, tracking disabled, not found.
