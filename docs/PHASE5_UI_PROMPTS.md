# Phase 5 UI Prompts (Driver Scoring + Driver Documents + Vehicle Insurance)

## Admin Dashboard Prompt
Implement a Driver Performance module and Vehicle Insurance section.

- Driver list/detail:
  - `GET /api/v1/drivers`
  - `GET /api/v1/drivers/:id`
  - `PATCH /api/v1/drivers/:id`
- Leaderboard and score history:
  - `GET /api/v1/drivers/leaderboard`
  - `GET /api/v1/drivers/:id/scores`
  - `GET /api/v1/drivers/:id/scores/current`
  - `GET /api/v1/drivers/:id/badges`
- Driver documents:
  - list/upload/update/verify
  - expiring and compliance summary endpoints
- Scoring config admin:
  - `GET /api/v1/admin/scoring_config`
  - `PATCH /api/v1/admin/scoring_config`

## Driver Mobile Prompt
Implement self-service driver profile and compliance views.

- My profile / score / badges / rank / tips:
  - `/api/v1/me/profile`
  - `/api/v1/me/scores`
  - `/api/v1/me/badges`
  - `/api/v1/me/rank`
  - `/api/v1/me/improvement_tips`
- My documents:
  - `/api/v1/me/documents`
  - upload via `/api/v1/me/documents`

## Vehicle Insurance Prompt (Required)
Add insurance data and document upload to Vehicle management/view pages.

- Vehicle create/update form fields:
  - `insurance_policy_number`
  - `insurance_provider`
  - `insurance_issued_at`
  - `insurance_expires_at`
  - `insurance_coverage_amount`
  - `insurance_notes`
  - `insurance_document` (file upload)
- Vehicle detail page:
  - show insurance summary and expiry status
  - open/download uploaded insurance document from `insurance.document_url`
- Backend integration:
  - use existing `POST/PATCH /vehicles` payload and include multipart file for `insurance_document`.
