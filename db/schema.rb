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

ActiveRecord::Schema[8.0].define(version: 2026_02_06_105000) do
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
    t.boolean "load_area_ready", null: false
    t.integer "load_status", default: 0, null: false
    t.boolean "load_secured", null: false
    t.text "load_note"
    t.boolean "accepted", null: false
    t.datetime "accepted_at"
    t.string "waybill_number"
    t.string "assistant_name"
    t.string "assistant_phone"
    t.string "fuel_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["captured_by_id"], name: "index_pre_trip_inspections_on_captured_by_id"
    t.index ["load_status"], name: "index_pre_trip_inspections_on_load_status"
    t.index ["trip_id"], name: "index_pre_trip_inspections_on_trip_id", unique: true
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
    t.index ["dispatcher_id"], name: "index_trips_on_dispatcher_id"
    t.index ["driver_id"], name: "index_trips_on_driver_id"
    t.index ["end_odometer_captured_by_id"], name: "index_trips_on_end_odometer_captured_by_id"
    t.index ["reference_code"], name: "index_trips_on_reference_code"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "evidence", "trips"
  add_foreign_key "evidence", "users", column: "uploaded_by_id"
  add_foreign_key "location_pings", "trips"
  add_foreign_key "location_pings", "users", column: "recorded_by_id"
  add_foreign_key "pre_trip_inspections", "trips"
  add_foreign_key "pre_trip_inspections", "users", column: "captured_by_id"
  add_foreign_key "trip_events", "trips"
  add_foreign_key "trip_events", "users", column: "created_by_id"
  add_foreign_key "trip_stops", "trips"
  add_foreign_key "trips", "users", column: "dispatcher_id"
  add_foreign_key "trips", "users", column: "driver_id"
  add_foreign_key "trips", "users", column: "end_odometer_captured_by_id"
  add_foreign_key "trips", "users", column: "start_odometer_captured_by_id"
  add_foreign_key "trips", "vehicles"
end
