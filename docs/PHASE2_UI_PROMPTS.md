# Phase 2 UI Prompts (Notification Engine)

## Admin Dashboard Prompt
Implement a Notification Control Center using Phase 2 endpoints.

- Build `Notifications` page:
  - list/filter (`GET /api/v1/notifications`) by category, type, priority, read status.
  - unread badge via `GET /api/v1/notifications/unread_count`.
  - actions: mark read, mark all read, archive, delete.
- Build `Preferences` page:
  - list defaults/user prefs (`GET /api/v1/notifications/preferences`).
  - bulk update (`PUT /api/v1/notifications/preferences`).
  - quiet hours (`PUT /api/v1/notifications/preferences/quiet_hours`).
- Build `Escalation Rules` admin page:
  - list/create/update (`/api/v1/admin/escalation_rules`).
  - active escalations board (`GET /api/v1/admin/escalations/active`).
- Show channel chips (`in_app`, `push`, `sms`, `email`), group key support, and priority color states.

## Driver Mobile Prompt
Implement notifications inbox and preferences for driver app.

- Inbox screen:
  - pull notifications (`GET /api/v1/notifications`), grouped optionally.
  - unread badge (`GET /api/v1/notifications/unread_count`).
  - mark as read/archive/swipe delete.
- Device token registration:
  - on login/refresh call `POST /api/v1/devices`.
  - on logout call `DELETE /api/v1/devices/:token`.
- Preferences screen:
  - read/update per notification type and quiet hours.
- Deep linking:
  - use `action_type`, `action_url`, `data` for navigation targets.
