class CreateClientPortalSystem < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :contact_name
      t.string :contact_email
      t.string :contact_phone
      t.string :billing_email
      t.text :address
      t.string :city
      t.string :region
      t.string :tax_id
      t.string :payment_terms
      t.string :contract_type
      t.string :rate_type
      t.decimal :default_rate, precision: 12, scale: 2
      t.decimal :credit_limit, precision: 12, scale: 2
      t.decimal :outstanding_balance, precision: 12, scale: 2, null: false, default: 0
      t.boolean :is_active, null: false, default: true
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :clients, :code, unique: true
    add_index :clients, :is_active
    add_index :clients, :name

    create_table :client_users do |t|
      t.references :client, null: false, foreign_key: true
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :phone
      t.string :role, null: false, default: "viewer"
      t.boolean :is_active, null: false, default: true
      t.datetime :last_login_at
      t.jsonb :notification_prefs, null: false, default: {}

      t.timestamps
    end
    add_index :client_users, :email, unique: true

    create_table :shipments do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :tracking_number, null: false
      t.string :reference_number
      t.string :description
      t.string :commodity_type
      t.decimal :weight_kg, precision: 12, scale: 2
      t.decimal :volume_cbm, precision: 12, scale: 2
      t.integer :pieces_count
      t.text :pickup_address
      t.text :delivery_address
      t.datetime :requested_pickup_date
      t.datetime :requested_delivery_date
      t.datetime :actual_pickup_at
      t.datetime :actual_delivery_at
      t.string :status, null: false
      t.decimal :rate_amount, precision: 12, scale: 2
      t.string :rate_type
      t.bigint :invoice_id
      t.text :special_instructions
      t.boolean :is_tracking_enabled, null: false, default: true
      t.string :tracking_link_token, null: false
      t.datetime :tracking_link_expires_at
      t.boolean :pod_available, null: false, default: false
      t.integer :client_rating
      t.text :client_feedback
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :shipments, :tracking_number, unique: true
    add_index :shipments, :tracking_link_token, unique: true
    add_index :shipments, :status

    create_table :shipment_events do |t|
      t.references :shipment, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :title, null: false
      t.text :description
      t.string :location
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.boolean :is_public, null: false, default: true

      t.timestamps
    end
    add_index :shipment_events, :event_type
    add_index :shipment_events, [:shipment_id, :created_at]

    create_table :invoices do |t|
      t.references :client, null: false, foreign_key: true
      t.string :invoice_number, null: false
      t.date :issued_date
      t.date :due_date
      t.decimal :subtotal, precision: 12, scale: 2, null: false, default: 0
      t.decimal :tax_rate, precision: 6, scale: 2, null: false, default: 0
      t.decimal :tax_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :amount_paid, precision: 12, scale: 2, null: false, default: 0
      t.decimal :balance_due, precision: 12, scale: 2, null: false, default: 0
      t.string :status, null: false, default: "draft"
      t.string :payment_terms
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, :status

    create_table :invoice_line_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.references :shipment, null: true, foreign_key: true
      t.string :description, null: false
      t.decimal :quantity, precision: 12, scale: 3, null: false, default: 1
      t.string :unit
      t.decimal :unit_price, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_reference :trips, :client, null: true, foreign_key: true
    add_column :trips, :client_reference, :string
  end
end
