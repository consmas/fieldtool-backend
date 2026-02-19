# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_19_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chat_conversation_messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "sender_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "idx_chat_conversation_messages_timeline"
    t.index ["conversation_id"], name: "index_chat_conversation_messages_on_conversation_id"
    t.index ["sender_id"], name: "index_chat_conversation_messages_on_sender_id"
  end

  create_table "chat_conversation_participants", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "user_id", null: false
    t.datetime "last_read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "user_id"], name: "idx_chat_conversation_participants_unique", unique: true
    t.index ["conversation_id"], name: "index_chat_conversation_participants_on_conversation_id"
    t.index ["last_read_at"], name: "index_chat_conversation_participants_on_last_read_at"
    t.index ["user_id"], name: "index_chat_conversation_participants_on_user_id"
  end

  create_table "chat_conversations", force: :cascade do |t|
    t.integer "kind", default: 0, null: false
    t.string "title"
    t.bigint "created_by_id"
    t.datetime "last_message_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_chat_conversations_on_created_by_id"
    t.index ["kind"], name: "index_chat_conversations_on_kind"
    t.index ["last_message_at"], name: "index_chat_conversations_on_last_message_at"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "chat_thread_id", null: false
    t.bigint "sender_id", null: false
    t.text "body", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_thread_id", "created_at"], name: "index_chat_messages_on_chat_thread_id_and_created_at"
    t.index ["chat_thread_id"], name: "index_chat_messages_on_chat_thread_id"
    t.index ["read_at"], name: "index_chat_messages_on_read_at"
    t.index ["sender_id"], name: "index_chat_messages_on_sender_id"
  end

  create_table "chat_threads", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.bigint "driver_id", null: false
    t.bigint "dispatcher_id"
    t.datetime "last_message_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dispatcher_id"], name: "index_chat_threads_on_dispatcher_id"
    t.index ["driver_id"], name: "index_chat_threads_on_driver_id"
    t.index ["trip_id"], name: "index_chat_threads_on_trip_id", unique: true
  end

  create_table "client_users", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "role", default: "viewer", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "last_login_at"
    t.jsonb "notification_prefs", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_users_on_client_id"
    t.index ["email"], name: "index_client_users_on_email", unique: true
  end

  create_table "clients", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "contact_name"
    t.string "contact_email"
    t.string "contact_phone"
    t.string "billing_email"
    t.text "address"
    t.string "city"
    t.string "region"
    t.string "tax_id"
    t.string "payment_terms"
    t.string "contract_type"
    t.string "rate_type"
    t.decimal "default_rate", precision: 12, scale: 2
    t.decimal "credit_limit", precision: 12, scale: 2
    t.decimal "outstanding_balance", precision: 12, scale: 2, default: "0.0", null: false
    t.boolean "is_active", default: true, null: false
    t.text "notes"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_clients_on_code", unique: true
    t.index ["is_active"], name: "index_clients_on_is_active"
    t.index ["name"], name: "index_clients_on_name"
  end

  create_table "destinations", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "average_distance_km", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "base_price_per_ton", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "tons_per_trip", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "kms_per_liter", precision: 10, scale: 2, default: "3.0", null: false
    t.decimal "fuel_price_ref", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "additional_provision_pct", precision: 5, scale: 2, default: "0.25", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "base_km", precision: 10, scale: 2, default: "100.0", null: false
    t.decimal "base_trip_cost", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "liters_per_km", precision: 10, scale: 2, default: "1.0", null: false
    t.index ["active"], name: "index_destinations_on_active"
    t.index ["name"], name: "index_destinations_on_name", unique: true
  end

  create_table "device_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.string "platform", null: false
    t.string "device_name"
    t.boolean "is_active", default: true, null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_device_tokens_on_is_active"
    t.index ["token"], name: "index_device_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_device_tokens_on_user_id"
  end

  create_table "escalation_instances", force: :cascade do |t|
    t.bigint "escalation_rule_id", null: false
    t.bigint "notification_id", null: false
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.integer "current_level", default: 0, null: false
    t.string "status", default: "active", null: false
    t.datetime "last_escalated_at"
    t.datetime "resolved_at"
    t.bigint "resolved_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["escalation_rule_id"], name: "index_escalation_instances_on_escalation_rule_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_escalation_instances_notifiable"
    t.index ["notification_id"], name: "index_escalation_instances_on_notification_id"
    t.index ["resolved_by_id"], name: "index_escalation_instances_on_resolved_by_id"
    t.index ["status"], name: "index_escalation_instances_on_status"
  end

  create_table "escalation_rules", force: :cascade do |t|
    t.string "name", null: false
    t.string "trigger_event", null: false
    t.string "condition_type", null: false
    t.integer "condition_minutes", null: false
    t.integer "escalation_level", default: 1, null: false
    t.string "escalate_to_role"
    t.bigint "escalate_to_user_id"
    t.string "escalation_channels", default: [], null: false, array: true
    t.string "escalation_priority", default: "high", null: false
    t.string "escalation_message"
    t.integer "max_escalations", default: 3, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["escalate_to_user_id"], name: "index_escalation_rules_on_escalate_to_user_id"
    t.index ["is_active"], name: "index_escalation_rules_on_is_active"
    t.index ["trigger_event"], name: "index_escalation_rules_on_trigger_event"
  end

  create_table "evidence", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.integer "kind", default: 0, null: false
    t.text "note"
    t.decimal "lat", precision: 10, scale: 6
    t.decimal "lng", precision: 10, scale: 6
    t.datetime "recorded_at", null: false
    t.bigint "uploaded_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_evidence_on_kind"
    t.index ["trip_id", "recorded_at"], name: "index_evidence_on_trip_id_and_recorded_at"
    t.index ["trip_id"], name: "index_evidence_on_trip_id"
    t.index ["uploaded_by_id"], name: "index_evidence_on_uploaded_by_id"
  end

  create_table "expense_entries", force: :cascade do |t|
    t.bigint "trip_id"
    t.bigint "vehicle_id"
    t.bigint "driver_id"
    t.integer "category", null: false
    t.string "subcategory"
    t.text "description"
    t.decimal "quantity", precision: 12, scale: 3
    t.decimal "unit_cost", precision: 12, scale: 3
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "currency", default: "GHS", null: false
    t.integer "status", default: 0, null: false
    t.datetime "expense_date", null: false
    t.string "payment_method"
    t.string "reference"
    t.string "vendor_name"
    t.string "receipt_url"
    t.boolean "is_auto_generated", default: false, null: false
    t.string "auto_rule_key"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "created_by_id"
    t.bigint "approved_by_id"
    t.bigint "paid_by_id"
    t.datetime "approved_at"
    t.datetime "paid_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_expense_entries_on_approved_by_id"
    t.index ["category"], name: "index_expense_entries_on_category"
    t.index ["created_by_id"], name: "index_expense_entries_on_created_by_id"
    t.index ["deleted_at"], name: "index_expense_entries_on_deleted_at"
    t.index ["driver_id"], name: "index_expense_entries_on_driver_id"
    t.index ["expense_date"], name: "index_expense_entries_on_expense_date"
    t.index ["is_auto_generated", "auto_rule_key"], name: "index_expense_entries_on_is_auto_generated_and_auto_rule_key"
    t.index ["paid_by_id"], name: "index_expense_entries_on_paid_by_id"
    t.index ["status"], name: "index_expense_entries_on_status"
    t.index ["trip_id", "category", "auto_rule_key", "deleted_at"], name: "index_expense_entries_on_trip_category_rule"
    t.index ["trip_id"], name: "index_expense_entries_on_trip_id"
    t.index ["vehicle_id"], name: "index_expense_entries_on_vehicle_id"
  end

  create_table "expense_entry_audits", force: :cascade do |t|
    t.bigint "expense_entry_id", null: false
    t.bigint "actor_id"
    t.string "action", null: false
    t.string "from_status"
    t.string "to_status"
    t.text "reason"
    t.jsonb "changeset", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_expense_entry_audits_on_action"
    t.index ["actor_id"], name: "index_expense_entry_audits_on_actor_id"
    t.index ["created_at"], name: "index_expense_entry_audits_on_created_at"
    t.index ["expense_entry_id"], name: "index_expense_entry_audits_on_expense_entry_id"
  end

  create_table "failed_jobs", force: :cascade do |t|
    t.string "job_class", null: false
    t.string "queue_name"
    t.jsonb "arguments", default: [], null: false
    t.string "error_class"
    t.text "error_message"
    t.text "backtrace"
    t.string "status", default: "failed", null: false
    t.string "context"
    t.datetime "failed_at", null: false
    t.datetime "retried_at"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["failed_at"], name: "index_failed_jobs_on_failed_at"
    t.index ["job_class"], name: "index_failed_jobs_on_job_class"
    t.index ["queue_name"], name: "index_failed_jobs_on_queue_name"
    t.index ["status"], name: "index_failed_jobs_on_status"
  end

  create_table "fuel_prices", force: :cascade do |t|
    t.decimal "price_per_liter", precision: 10, scale: 2, null: false
    t.datetime "effective_at", null: false
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["effective_at"], name: "index_fuel_prices_on_effective_at"
    t.index ["updated_by_id"], name: "index_fuel_prices_on_updated_by_id"
  end

  create_table "invoice_line_items", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.bigint "shipment_id"
    t.string "description", null: false
    t.decimal "quantity", precision: 12, scale: 3, default: "1.0", null: false
    t.string "unit"
    t.decimal "unit_price", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_line_items_on_invoice_id"
    t.index ["shipment_id"], name: "index_invoice_line_items_on_shipment_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.string "invoice_number", null: false
    t.date "issued_date"
    t.date "due_date"
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tax_rate", precision: 6, scale: 2, default: "0.0", null: false
    t.decimal "tax_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "amount_paid", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "balance_due", precision: 12, scale: 2, default: "0.0", null: false
    t.string "status", default: "draft", null: false
    t.string "payment_terms"
    t.text "notes"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.index ["status"], name: "index_invoices_on_status"
  end

  create_table "location_pings", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.decimal "lat", precision: 10, scale: 6, null: false
    t.decimal "lng", precision: 10, scale: 6, null: false
    t.decimal "speed", precision: 8, scale: 2
    t.decimal "heading", precision: 6, scale: 2
    t.datetime "recorded_at", null: false
    t.bigint "recorded_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recorded_by_id"], name: "index_location_pings_on_recorded_by_id"
    t.index ["trip_id", "recorded_at"], name: "index_location_pings_on_trip_id_and_recorded_at"
    t.index ["trip_id"], name: "index_location_pings_on_trip_id"
  end

  create_table "maintenance_schedules", force: :cascade do |t|
    t.bigint "vehicle_id"
    t.string "vehicle_type"
    t.string "name", null: false
    t.text "description"
    t.string "schedule_type", null: false
    t.integer "mileage_interval_km"
    t.integer "time_interval_days"
    t.datetime "last_performed_at"
    t.integer "last_performed_km"
    t.datetime "next_due_at"
    t.integer "next_due_km"
    t.string "priority", default: "medium", null: false
    t.boolean "is_active", default: true, null: false
    t.integer "notify_before_km", default: 0, null: false
    t.integer "notify_before_days", default: 0, null: false
    t.decimal "estimated_duration_hrs", precision: 6, scale: 2
    t.decimal "estimated_cost", precision: 12, scale: 2
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_maintenance_schedules_on_created_by_id"
    t.index ["is_active"], name: "index_maintenance_schedules_on_is_active"
    t.index ["next_due_at"], name: "index_maintenance_schedules_on_next_due_at"
    t.index ["next_due_km"], name: "index_maintenance_schedules_on_next_due_km"
    t.index ["priority"], name: "index_maintenance_schedules_on_priority"
    t.index ["vehicle_id"], name: "index_maintenance_schedules_on_vehicle_id"
    t.index ["vehicle_type"], name: "index_maintenance_schedules_on_vehicle_type"
  end

  create_table "maintenance_vendors", force: :cascade do |t|
    t.string "name", null: false
    t.string "contact_name"
    t.string "phone"
    t.string "email"
    t.text "address"
    t.string "city"
    t.string "specializations", default: [], null: false, array: true
    t.decimal "rating", precision: 3, scale: 2
    t.boolean "is_active", default: true, null: false
    t.text "notes"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_maintenance_vendors_on_city"
    t.index ["is_active"], name: "index_maintenance_vendors_on_is_active"
    t.index ["specializations"], name: "index_maintenance_vendors_on_specializations", using: :gin
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notification_type", null: false
    t.boolean "in_app", default: true, null: false
    t.boolean "push", default: false, null: false
    t.boolean "sms", default: false, null: false
    t.boolean "email", default: false, null: false
    t.boolean "is_enabled", default: true, null: false
    t.time "quiet_hours_start"
    t.time "quiet_hours_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "notification_type"], name: "index_notification_prefs_user_type", unique: true
    t.index ["user_id"], name: "index_notification_preferences_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "recipient_id", null: false
    t.bigint "actor_id"
    t.string "notification_type", null: false
    t.string "category", null: false
    t.string "title", null: false
    t.text "body"
    t.string "priority", default: "normal", null: false
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.string "action_url"
    t.string "action_type"
    t.jsonb "data", default: {}, null: false
    t.datetime "read_at"
    t.datetime "seen_at"
    t.datetime "archived_at"
    t.string "delivered_via", default: [], null: false, array: true
    t.datetime "expires_at"
    t.string "group_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["category"], name: "index_notifications_on_category"
    t.index ["group_key"], name: "index_notifications_on_group_key"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["priority"], name: "index_notifications_on_priority"
    t.index ["read_at"], name: "index_notifications_on_read_at"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "pre_trip_inspections", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.bigint "captured_by_id", null: false
    t.decimal "odometer_value_km", precision: 10, scale: 1, null: false
    t.datetime "odometer_captured_at", null: false
    t.decimal "odometer_lat", precision: 10, scale: 6
    t.decimal "odometer_lng", precision: 10, scale: 6
    t.boolean "brakes", null: false
    t.boolean "tyres", null: false
    t.boolean "lights", null: false
    t.boolean "mirrors", null: false
    t.boolean "horn", null: false
    t.boolean "fuel_sufficient", null: false
    t.boolean "load_area_ready"
    t.integer "load_status"
    t.boolean "load_secured"
    t.text "load_note"
    t.boolean "accepted", null: false
    t.datetime "accepted_at"
    t.string "waybill_number"
    t.string "assistant_name"
    t.string "assistant_phone"
    t.string "fuel_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "inspection_verification_status", default: 0, null: false
    t.bigint "inspection_verified_by_id"
    t.datetime "inspection_verified_at"
    t.text "inspection_verification_note"
    t.boolean "inspection_confirmed", default: false, null: false
    t.bigint "inspection_confirmed_by_id"
    t.datetime "inspection_confirmed_at"
    t.jsonb "core_checklist", default: {}, null: false
    t.index ["captured_by_id"], name: "index_pre_trip_inspections_on_captured_by_id"
    t.index ["inspection_confirmed_by_id"], name: "index_pre_trip_inspections_on_inspection_confirmed_by_id"
    t.index ["inspection_verification_status"], name: "index_pre_trip_inspections_on_inspection_verification_status"
    t.index ["inspection_verified_by_id"], name: "index_pre_trip_inspections_on_inspection_verified_by_id"
    t.index ["load_status"], name: "index_pre_trip_inspections_on_load_status"
    t.index ["trip_id"], name: "index_pre_trip_inspections_on_trip_id", unique: true
  end

  create_table "shipment_events", force: :cascade do |t|
    t.bigint "shipment_id", null: false
    t.string "event_type", null: false
    t.string "title", null: false
    t.text "description"
    t.string "location"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.boolean "is_public", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_shipment_events_on_event_type"
    t.index ["shipment_id", "created_at"], name: "index_shipment_events_on_shipment_id_and_created_at"
    t.index ["shipment_id"], name: "index_shipment_events_on_shipment_id"
  end

  create_table "shipments", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.bigint "client_id", null: false
    t.string "tracking_number", null: false
    t.string "reference_number"
    t.string "description"
    t.string "commodity_type"
    t.decimal "weight_kg", precision: 12, scale: 2
    t.decimal "volume_cbm", precision: 12, scale: 2
    t.integer "pieces_count"
    t.text "pickup_address"
    t.text "delivery_address"
    t.datetime "requested_pickup_date"
    t.datetime "requested_delivery_date"
    t.datetime "actual_pickup_at"
    t.datetime "actual_delivery_at"
    t.string "status", null: false
    t.decimal "rate_amount", precision: 12, scale: 2
    t.string "rate_type"
    t.bigint "invoice_id"
    t.text "special_instructions"
    t.boolean "is_tracking_enabled", default: true, null: false
    t.string "tracking_link_token", null: false
    t.datetime "tracking_link_expires_at"
    t.boolean "pod_available", default: false, null: false
    t.integer "client_rating"
    t.text "client_feedback"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_shipments_on_client_id"
    t.index ["status"], name: "index_shipments_on_status"
    t.index ["tracking_link_token"], name: "index_shipments_on_tracking_link_token", unique: true
    t.index ["tracking_number"], name: "index_shipments_on_tracking_number", unique: true
    t.index ["trip_id"], name: "index_shipments_on_trip_id"
  end

  create_table "trip_events", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.string "event_type", null: false
    t.string "message"
    t.jsonb "data", default: {}, null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_trip_events_on_created_by_id"
    t.index ["event_type"], name: "index_trip_events_on_event_type"
    t.index ["trip_id", "created_at"], name: "index_trip_events_on_trip_id_and_created_at"
    t.index ["trip_id"], name: "index_trip_events_on_trip_id"
  end

  create_table "trip_stops", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.integer "sequence", null: false
    t.string "destination"
    t.string "delivery_address"
    t.string "tonnage_load"
    t.string "waybill_number"
    t.string "customer_contact_name"
    t.string "customer_contact_phone"
    t.text "special_instructions"
    t.time "arrival_time_at_site"
    t.integer "pod_type", default: 0, null: false
    t.boolean "waybill_returned"
    t.text "notes_incidents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pod_type"], name: "index_trip_stops_on_pod_type"
    t.index ["trip_id", "sequence"], name: "index_trip_stops_on_trip_id_and_sequence", unique: true
    t.index ["trip_id"], name: "index_trip_stops_on_trip_id"
  end

  create_table "trips", force: :cascade do |t|
    t.string "reference_code"
    t.integer "status", default: 0, null: false
    t.bigint "driver_id", null: false
    t.bigint "dispatcher_id"
    t.string "pickup_location"
    t.string "dropoff_location"
    t.text "pickup_notes"
    t.text "dropoff_notes"
    t.string "material_description"
    t.datetime "scheduled_pickup_at"
    t.datetime "scheduled_dropoff_at"
    t.decimal "start_odometer_km", precision: 10, scale: 1
    t.decimal "end_odometer_km", precision: 10, scale: 1
    t.datetime "start_odometer_captured_at"
    t.datetime "end_odometer_captured_at"
    t.bigint "start_odometer_captured_by_id"
    t.bigint "end_odometer_captured_by_id"
    t.text "start_odometer_note"
    t.text "end_odometer_note"
    t.decimal "start_odometer_lat", precision: 10, scale: 6
    t.decimal "start_odometer_lng", precision: 10, scale: 6
    t.decimal "end_odometer_lat", precision: 10, scale: 6
    t.decimal "end_odometer_lng", precision: 10, scale: 6
    t.datetime "status_changed_at"
    t.datetime "completed_at"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "waybill_number"
    t.date "trip_date"
    t.string "truck_reg_no"
    t.string "driver_contact"
    t.string "truck_type_capacity"
    t.decimal "road_expense_disbursed", precision: 10, scale: 2
    t.string "road_expense_reference"
    t.string "client_name"
    t.string "destination"
    t.string "delivery_address"
    t.string "tonnage_load"
    t.time "estimated_departure_time"
    t.time "estimated_arrival_time"
    t.string "customer_contact_name"
    t.string "customer_contact_phone"
    t.text "special_instructions"
    t.time "arrival_time_at_site"
    t.integer "pod_type", default: 0, null: false
    t.boolean "waybill_returned"
    t.text "notes_incidents"
    t.string "fuel_station_used"
    t.integer "fuel_payment_mode", default: 0, null: false
    t.decimal "fuel_litres_filled", precision: 10, scale: 2
    t.string "fuel_receipt_no"
    t.time "return_time"
    t.integer "vehicle_condition_post_trip", default: 0, null: false
    t.string "post_trip_inspector_name"
    t.bigint "vehicle_id"
    t.decimal "distance_km", precision: 12, scale: 3, default: "0.0", null: false
    t.datetime "distance_computed_at"
    t.decimal "last_snapped_lat", precision: 10, scale: 6
    t.decimal "last_snapped_lng", precision: 10, scale: 6
    t.decimal "fuel_allocated_litres", precision: 10, scale: 2
    t.string "fuel_allocation_station"
    t.integer "fuel_allocation_payment_mode"
    t.string "fuel_allocation_reference"
    t.bigint "fuel_allocated_by_id"
    t.datetime "fuel_allocated_at"
    t.text "fuel_allocation_note"
    t.integer "road_expense_payment_status", default: 0, null: false
    t.datetime "road_expense_paid_at"
    t.bigint "road_expense_paid_by_id"
    t.integer "road_expense_payment_method"
    t.string "road_expense_payment_reference"
    t.text "road_expense_note"
    t.string "delivery_place_id"
    t.decimal "delivery_lat", precision: 10, scale: 6
    t.decimal "delivery_lng", precision: 10, scale: 6
    t.string "delivery_map_url"
    t.string "delivery_location_source"
    t.datetime "delivery_location_resolved_at"
    t.bigint "client_id"
    t.string "client_reference"
    t.index ["client_id"], name: "index_trips_on_client_id"
    t.index ["delivery_lat", "delivery_lng"], name: "index_trips_on_delivery_lat_and_delivery_lng"
    t.index ["delivery_place_id"], name: "index_trips_on_delivery_place_id"
    t.index ["dispatcher_id"], name: "index_trips_on_dispatcher_id"
    t.index ["driver_id"], name: "index_trips_on_driver_id"
    t.index ["end_odometer_captured_by_id"], name: "index_trips_on_end_odometer_captured_by_id"
    t.index ["fuel_allocated_by_id"], name: "index_trips_on_fuel_allocated_by_id"
    t.index ["reference_code"], name: "index_trips_on_reference_code"
    t.index ["road_expense_paid_by_id"], name: "index_trips_on_road_expense_paid_by_id"
    t.index ["road_expense_payment_status"], name: "index_trips_on_road_expense_payment_status"
    t.index ["start_odometer_captured_by_id"], name: "index_trips_on_start_odometer_captured_by_id"
    t.index ["status"], name: "index_trips_on_status"
    t.index ["vehicle_id"], name: "index_trips_on_vehicle_id"
    t.index ["waybill_number"], name: "index_trips_on_waybill_number"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "role", default: 0, null: false
    t.string "jti", default: "", null: false
    t.string "phone_number"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vehicle_documents", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.string "document_type", null: false
    t.string "document_number"
    t.date "issued_at"
    t.date "expires_at"
    t.string "issuing_authority"
    t.decimal "cost", precision: 12, scale: 2
    t.string "status", default: "active", null: false
    t.integer "notify_before_days", default: 30, null: false
    t.text "notes"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_type"], name: "index_vehicle_documents_on_document_type"
    t.index ["expires_at"], name: "index_vehicle_documents_on_expires_at"
    t.index ["status"], name: "index_vehicle_documents_on_status"
    t.index ["vehicle_id"], name: "index_vehicle_documents_on_vehicle_id"
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "name", null: false
    t.integer "kind", default: 0, null: false
    t.string "license_plate"
    t.string "vin"
    t.text "notes"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "truck_type_capacity"
    t.index ["active"], name: "index_vehicles_on_active"
    t.index ["kind"], name: "index_vehicles_on_kind"
    t.index ["license_plate"], name: "index_vehicles_on_license_plate"
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.bigint "webhook_subscription_id", null: false
    t.bigint "webhook_event_id"
    t.string "event_type", null: false
    t.string "idempotency_key", null: false
    t.jsonb "payload", default: {}, null: false
    t.string "status", default: "pending", null: false
    t.integer "attempts", default: 0, null: false
    t.integer "max_attempts", default: 5, null: false
    t.datetime "last_attempt_at"
    t.datetime "next_retry_at"
    t.integer "response_code"
    t.text "response_body"
    t.integer "response_duration_ms"
    t.string "error_message"
    t.datetime "delivered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_webhook_deliveries_on_event_type"
    t.index ["idempotency_key"], name: "index_webhook_deliveries_on_idempotency_key", unique: true
    t.index ["next_retry_at"], name: "index_webhook_deliveries_on_next_retry_at"
    t.index ["status"], name: "index_webhook_deliveries_on_status"
    t.index ["webhook_event_id"], name: "index_webhook_deliveries_on_webhook_event_id"
    t.index ["webhook_subscription_id"], name: "index_webhook_deliveries_on_webhook_subscription_id"
  end

  create_table "webhook_events", force: :cascade do |t|
    t.string "event_type", null: false
    t.string "resource_type"
    t.bigint "resource_id"
    t.jsonb "payload", default: {}, null: false
    t.bigint "triggered_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_webhook_events_on_event_type"
    t.index ["resource_type", "resource_id"], name: "index_webhook_events_on_resource_type_and_resource_id"
    t.index ["triggered_by"], name: "index_webhook_events_on_triggered_by"
  end

  create_table "webhook_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id"
    t.string "url", null: false
    t.string "secret", null: false
    t.string "event_types", default: [], null: false, array: true
    t.boolean "is_active", default: true, null: false
    t.string "description"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "last_triggered_at"
    t.integer "failure_count", default: 0, null: false
    t.datetime "disabled_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_webhook_subscriptions_on_deleted_at"
    t.index ["event_types"], name: "index_webhook_subscriptions_on_event_types", using: :gin
    t.index ["is_active"], name: "index_webhook_subscriptions_on_is_active"
    t.index ["organization_id"], name: "index_webhook_subscriptions_on_organization_id"
    t.index ["user_id"], name: "index_webhook_subscriptions_on_user_id"
  end

  create_table "work_order_comments", force: :cascade do |t|
    t.bigint "work_order_id", null: false
    t.bigint "user_id", null: false
    t.text "comment", null: false
    t.string "comment_type", default: "note", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_type"], name: "index_work_order_comments_on_comment_type"
    t.index ["user_id"], name: "index_work_order_comments_on_user_id"
    t.index ["work_order_id"], name: "index_work_order_comments_on_work_order_id"
  end

  create_table "work_order_parts", force: :cascade do |t|
    t.bigint "work_order_id", null: false
    t.string "part_name", null: false
    t.string "part_number"
    t.decimal "quantity", precision: 12, scale: 3, default: "1.0", null: false
    t.string "unit"
    t.decimal "unit_cost", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total_cost", precision: 12, scale: 2, default: "0.0", null: false
    t.string "supplier"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["work_order_id"], name: "index_work_order_parts_on_work_order_id"
  end

  create_table "work_orders", force: :cascade do |t|
    t.string "work_order_number", null: false
    t.bigint "vehicle_id", null: false
    t.bigint "maintenance_schedule_id"
    t.string "title", null: false
    t.text "description"
    t.string "work_order_type", default: "preventive", null: false
    t.string "status", default: "draft", null: false
    t.string "priority", default: "medium", null: false
    t.string "assigned_to"
    t.string "assigned_to_type"
    t.bigint "vendor_id"
    t.bigint "reported_by_id"
    t.datetime "reported_at"
    t.date "scheduled_date"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "odometer_at_creation"
    t.decimal "estimated_cost", precision: 12, scale: 2
    t.decimal "actual_cost", precision: 12, scale: 2
    t.decimal "labor_hours", precision: 8, scale: 2
    t.decimal "labor_cost", precision: 12, scale: 2
    t.decimal "parts_cost", precision: 12, scale: 2
    t.text "notes"
    t.text "resolution_notes"
    t.string "failure_reason"
    t.decimal "downtime_hours", precision: 8, scale: 2
    t.jsonb "metadata", default: {}, null: false
    t.bigint "expense_entry_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_entry_id"], name: "index_work_orders_on_expense_entry_id"
    t.index ["maintenance_schedule_id"], name: "index_work_orders_on_maintenance_schedule_id"
    t.index ["priority"], name: "index_work_orders_on_priority"
    t.index ["reported_by_id"], name: "index_work_orders_on_reported_by_id"
    t.index ["scheduled_date"], name: "index_work_orders_on_scheduled_date"
    t.index ["status"], name: "index_work_orders_on_status"
    t.index ["vehicle_id"], name: "index_work_orders_on_vehicle_id"
    t.index ["vendor_id"], name: "index_work_orders_on_vendor_id"
    t.index ["work_order_number"], name: "index_work_orders_on_work_order_number", unique: true
    t.index ["work_order_type"], name: "index_work_orders_on_work_order_type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chat_conversation_messages", "chat_conversations", column: "conversation_id"
  add_foreign_key "chat_conversation_messages", "users", column: "sender_id"
  add_foreign_key "chat_conversation_participants", "chat_conversations", column: "conversation_id"
  add_foreign_key "chat_conversation_participants", "users"
  add_foreign_key "chat_conversations", "users", column: "created_by_id"
  add_foreign_key "chat_messages", "chat_threads"
  add_foreign_key "chat_messages", "users", column: "sender_id"
  add_foreign_key "chat_threads", "trips"
  add_foreign_key "chat_threads", "users", column: "dispatcher_id"
  add_foreign_key "chat_threads", "users", column: "driver_id"
  add_foreign_key "client_users", "clients"
  add_foreign_key "device_tokens", "users"
  add_foreign_key "escalation_instances", "escalation_rules"
  add_foreign_key "escalation_instances", "notifications"
  add_foreign_key "escalation_instances", "users", column: "resolved_by_id"
  add_foreign_key "escalation_rules", "users", column: "escalate_to_user_id"
  add_foreign_key "evidence", "trips"
  add_foreign_key "evidence", "users", column: "uploaded_by_id"
  add_foreign_key "expense_entries", "trips"
  add_foreign_key "expense_entries", "users", column: "approved_by_id"
  add_foreign_key "expense_entries", "users", column: "created_by_id"
  add_foreign_key "expense_entries", "users", column: "driver_id"
  add_foreign_key "expense_entries", "users", column: "paid_by_id"
  add_foreign_key "expense_entries", "vehicles"
  add_foreign_key "expense_entry_audits", "expense_entries"
  add_foreign_key "expense_entry_audits", "users", column: "actor_id"
  add_foreign_key "invoice_line_items", "invoices"
  add_foreign_key "invoice_line_items", "shipments"
  add_foreign_key "invoices", "clients"
  add_foreign_key "location_pings", "trips"
  add_foreign_key "location_pings", "users", column: "recorded_by_id"
  add_foreign_key "maintenance_schedules", "users", column: "created_by_id"
  add_foreign_key "maintenance_schedules", "vehicles"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "pre_trip_inspections", "trips"
  add_foreign_key "pre_trip_inspections", "users", column: "captured_by_id"
  add_foreign_key "shipment_events", "shipments"
  add_foreign_key "shipments", "clients"
  add_foreign_key "shipments", "trips"
  add_foreign_key "trip_events", "trips"
  add_foreign_key "trip_events", "users", column: "created_by_id"
  add_foreign_key "trip_stops", "trips"
  add_foreign_key "trips", "clients"
  add_foreign_key "trips", "users", column: "dispatcher_id"
  add_foreign_key "trips", "users", column: "driver_id"
  add_foreign_key "trips", "users", column: "end_odometer_captured_by_id"
  add_foreign_key "trips", "users", column: "start_odometer_captured_by_id"
  add_foreign_key "trips", "vehicles"
  add_foreign_key "vehicle_documents", "vehicles"
  add_foreign_key "webhook_deliveries", "webhook_events"
  add_foreign_key "webhook_deliveries", "webhook_subscriptions"
  add_foreign_key "webhook_subscriptions", "users"
  add_foreign_key "work_order_comments", "users"
  add_foreign_key "work_order_comments", "work_orders"
  add_foreign_key "work_order_parts", "work_orders"
  add_foreign_key "work_orders", "expense_entries"
  add_foreign_key "work_orders", "maintenance_schedules"
  add_foreign_key "work_orders", "maintenance_vendors", column: "vendor_id"
  add_foreign_key "work_orders", "users", column: "reported_by_id"
  add_foreign_key "work_orders", "vehicles"
end
