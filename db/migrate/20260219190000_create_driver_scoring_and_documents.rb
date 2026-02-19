class CreateDriverScoringAndDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :driver_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :employee_number
      t.string :license_number
      t.string :license_class
      t.date :license_issued_at
      t.date :license_expires_at
      t.string :license_issuing_authority
      t.date :date_of_birth
      t.date :date_hired
      t.string :emergency_contact_name
      t.string :emergency_contact_phone
      t.string :blood_type
      t.date :medical_fitness_expires_at
      t.integer :years_experience
      t.string :vehicle_types_qualified, array: true, null: false, default: []
      t.decimal :current_score, precision: 6, scale: 2
      t.string :score_tier, null: false, default: "bronze"
      t.integer :total_trips, null: false, default: 0
      t.decimal :total_distance_km, precision: 14, scale: 3, null: false, default: 0
      t.integer :total_incidents, null: false, default: 0
      t.boolean :is_active, null: false, default: true
      t.string :status, null: false, default: "active"
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :driver_profiles, :user_id, unique: true, name: "index_driver_profiles_on_user_id_unique"
    add_index :driver_profiles, :score_tier
    add_index :driver_profiles, :status

    create_table :driver_documents do |t|
      t.references :driver_profile, null: false, foreign_key: true
      t.string :document_type, null: false
      t.string :document_number
      t.string :title
      t.date :issued_at
      t.date :expires_at
      t.string :issuing_authority
      t.string :status, null: false, default: "active"
      t.integer :notify_before_days, null: false, default: 30
      t.string :verification_status, null: false, default: "unverified"
      t.references :verified_by, null: true, foreign_key: { to_table: :users }
      t.datetime :verified_at
      t.decimal :cost, precision: 12, scale: 2
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :driver_documents, :document_type
    add_index :driver_documents, :status
    add_index :driver_documents, :verification_status
    add_index :driver_documents, :expires_at

    create_table :driver_scores do |t|
      t.references :driver_profile, null: false, foreign_key: true
      t.string :scoring_period, null: false
      t.string :period_type, null: false
      t.decimal :overall_score, precision: 6, scale: 2, null: false
      t.decimal :safety_score, precision: 6, scale: 2, null: false
      t.decimal :efficiency_score, precision: 6, scale: 2, null: false
      t.decimal :compliance_score, precision: 6, scale: 2, null: false
      t.decimal :timeliness_score, precision: 6, scale: 2, null: false
      t.decimal :professionalism_score, precision: 6, scale: 2, null: false
      t.integer :trips_in_period, null: false, default: 0
      t.decimal :distance_in_period, precision: 14, scale: 3, null: false, default: 0
      t.integer :incidents_in_period, null: false, default: 0
      t.jsonb :score_details, null: false, default: {}
      t.integer :rank_in_fleet
      t.string :trend, null: false, default: "stable"
      t.string :badges_earned, null: false, default: [], array: true

      t.timestamps
    end
    add_index :driver_scores, [:driver_profile_id, :scoring_period], unique: true, name: "idx_driver_scores_unique_period"
    add_index :driver_scores, :overall_score

    create_table :driver_badges do |t|
      t.references :driver_profile, null: false, foreign_key: true
      t.string :badge_type, null: false
      t.string :title, null: false
      t.string :description
      t.string :icon
      t.datetime :earned_at, null: false
      t.string :scoring_period, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :driver_badges, [:driver_profile_id, :badge_type, :scoring_period], unique: true, name: "idx_driver_badges_unique"

    create_table :scoring_configs do |t|
      t.string :name, null: false
      t.jsonb :weights, null: false, default: {}
      t.jsonb :tier_thresholds, null: false, default: {}
      t.jsonb :badge_rules, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :scoring_configs, :name, unique: true

    add_column :vehicles, :insurance_policy_number, :string unless column_exists?(:vehicles, :insurance_policy_number)
    add_column :vehicles, :insurance_provider, :string unless column_exists?(:vehicles, :insurance_provider)
    add_column :vehicles, :insurance_issued_at, :date unless column_exists?(:vehicles, :insurance_issued_at)
    add_column :vehicles, :insurance_expires_at, :date unless column_exists?(:vehicles, :insurance_expires_at)
    add_column :vehicles, :insurance_coverage_amount, :decimal, precision: 14, scale: 2 unless column_exists?(:vehicles, :insurance_coverage_amount)
    add_column :vehicles, :insurance_notes, :text unless column_exists?(:vehicles, :insurance_notes)
  end
end
