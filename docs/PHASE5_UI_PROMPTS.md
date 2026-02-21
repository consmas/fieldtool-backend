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

## Reporting Format Alignment Prompt (From 2026 Monitoring Templates)
Refine Admin reports and exports to mirror these workbook structures:
- `2026 Consmas Reporting Regime.xlsx` (`Reporting`)
- `20260218 Consmas Monthy monitoring.xlsx`
- `Copy of Fleet Operations Budget - Feb 2026 .xlsx`

### 1) Monthly Monitoring Checklist (Regime Format)
Build a report page + export that uses these columns:
- `Monitoring Item`
- `Evidence Required`
- `Responsible`
- `Timeline`
- `Jan`..`Dec` status/value columns
- `Comments / Clause Reference`

Behavior:
- Allow status per month: `Submitted`, `Not Submitted`, `N/A`, `Not Required`.
- Provide year selector (default current year).
- Group rows by compliance domain:
  - Security perfection
  - Debt service payments / DSRA
  - Reporting obligations
  - Fleet deployment
  - Maintenance compliance

API use:
- compliance + audit + incidents + documents endpoints to populate status/evidence links.
- include export endpoint producing XLSX/CSV with identical column order.

### 2) Consmas Monthly Monitoring Workbook Layout
Create report tabs matching these sheets:
1. `Master Trip Operations Table`
2. `Fleet Status (Monthly)`
3. `Driver Performance (Monthly)`
4. `Insurance & Compliance Tracker`
5. `Incident & Damage Register`
6. `Fabrimetal Payment Monitoring`
7. `Service KPIs Monitor`
8. `Management Summary`

Required columns per tab:
- Master Trip Operations:
  - `Reporting Month`, `Trip ID`, `Waybill No.`, `Truck ID`, `Driver Name`, `Cargo Type`, `Origin`, `Destination`, `Planned Delivery`, `Actual Delivery`, `Status`
- Fleet Status:
  - `Reporting Month`, `Truck ID`, `Registration Number`, `Operational Status`, `Total Trips Completed (Month)`, `Downtime (Days)`, `Maintenance Conducted (Y/N)`, `Maintenance Type`
- Driver Performance:
  - `Reporting Month`, `Driver`, `Trips`, `Distance`, `Incidents`, `Score`, `Tier`, `Trend`
- Insurance & Compliance:
  - `Truck ID`, `Policy No`, `Insurer`, `Issue Date`, `Expiry Date`, `Road Worthiness`, `Registration`, `Compliance Status`
- Incident & Damage:
  - `Incident No`, `Date`, `Trip`, `Vehicle`, `Type`, `Severity`, `Status`, `Estimated Cost`, `Actual Cost`, `Claim Status`
- Fabrimetal Payment Monitoring:
  - `Month`, `Invoice No`, `Amount Due`, `Amount Paid`, `Paid Date`, `Outstanding`, `Variance`, `Notes`
- Service KPIs:
  - `KPI`, `Target`, `Actual`, `Variance`, `RAG`
- Management Summary:
  - auto-generated metrics and highlights from all tabs.

### 3) Budget Report Format (Revenue + Monthly Budget)
Support two export blocks:
- Revenue Breakdown:
  - `Budget Item`, `Number of Trips`, `Rate Per Trip`, `Amount (GHS)`
  - Include regional rows (e.g. Accra, Kumasi, Takoradi) + totals.
- Monthly Budget:
  - `Budget Item`, `Amount (GHS)`, `Remarks`
  - Include operational lines: regulatory/statutory, fuel, maintenance, driver cost, insurance, contingency.

### 4) Output Requirements
- Provide:
  - in-app report tables
  - downloadable CSV
  - downloadable XLSX template-compatible layout
- Preserve exact column names and ordering above for external compliance submission.
- Include `Generated At`, `Reporting Month`, `Prepared By`.
- Include validation warnings for missing mandatory evidence.

### 5) API Contracts for Reporting
Use and combine:
- `GET /api/v1/reports/maintenance`
- `GET /api/v1/reports/fuel`
- `GET /api/v1/reports/drivers`
- `GET /api/v1/reports/incidents`
- `GET /api/v1/reports/compliance`
- `GET /api/v1/audit/summary`
- `GET /api/v1/audit/logs`
- `GET /api/v1/vehicles/:vehicle_id/documents`
- `GET /api/v1/drivers/documents/compliance_summary`

### 6) Admin UX Constraints
- Month/year filters must drive all tabs consistently.
- Keep “submission readiness” score at top:
  - `% complete`, `missing evidence count`, `critical exceptions`.
- Add one-click `Mark as Submitted` action that records audit log entry.
