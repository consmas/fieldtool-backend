class CreateComplianceAuditIncidentSystem < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.uuid :event_id, null: false
      t.string :action, null: false
      t.string :category, null: false
      t.string :severity, null: false, default: "info"
      t.references :actor, null: true, foreign_key: { to_table: :users }, index: false
      t.string :actor_type, null: false, default: "system"
      t.string :actor_role
      t.string :actor_ip
      t.string :actor_user_agent
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.string :associated_type
      t.bigint :associated_id
      t.string :description
      t.jsonb :changeset, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.uuid :request_id
      t.string :session_id
      t.datetime :occurred_at, null: false

      t.timestamps
    end
    remove_column :audit_logs, :updated_at
    add_index :audit_logs, :event_id, unique: true
    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, [:associated_type, :associated_id]
    add_index :audit_logs, :actor_id
    add_index :audit_logs, :action
    add_index :audit_logs, :category
    add_index :audit_logs, :severity
    add_index :audit_logs, :occurred_at
    add_index :audit_logs, :request_id
    add_index :audit_logs, :changeset, using: :gin
    add_index :audit_logs, :metadata, using: :gin

    create_table :incidents do |t|
      t.string :incident_number, null: false
      t.references :trip, null: true, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.references :driver, null: false, foreign_key: { to_table: :users }
      t.references :reported_by, null: false, foreign_key: { to_table: :users }
      t.string :incident_type, null: false
      t.string :severity, null: false
      t.string :status, null: false, default: "reported"
      t.string :title, null: false
      t.text :description
      t.datetime :incident_date, null: false
      t.string :incident_location
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :weather_conditions
      t.string :road_conditions
      t.boolean :injuries_reported, null: false, default: false
      t.text :injuries_description
      t.integer :fatalities, null: false, default: 0
      t.boolean :third_party_involved, null: false, default: false
      t.text :third_party_details
      t.string :police_report_number
      t.string :police_station
      t.decimal :estimated_damage_cost, precision: 12, scale: 2
      t.decimal :actual_damage_cost, precision: 12, scale: 2
      t.text :vehicle_damage_description
      t.text :cargo_damage_description
      t.decimal :cargo_damage_value, precision: 12, scale: 2
      t.boolean :vehicle_drivable
      t.boolean :towing_required
      t.string :root_cause
      t.string :root_cause_category
      t.text :corrective_actions
      t.text :preventive_measures
      t.references :assigned_investigator, null: true, foreign_key: { to_table: :users }
      t.datetime :investigation_started_at
      t.datetime :investigation_completed_at
      t.datetime :resolved_at
      t.references :resolved_by, null: true, foreign_key: { to_table: :users }
      t.text :closure_notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :incidents, :incident_number, unique: true
    add_index :incidents, :status
    add_index :incidents, :incident_type
    add_index :incidents, :severity
    add_index :incidents, :incident_date

    create_table :incident_witnesses do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.string :relationship
      t.text :statement
      t.datetime :statement_date
      t.text :notes

      t.timestamps
    end

    create_table :incident_evidence do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :evidence_type, null: false
      t.string :category, null: false
      t.string :title
      t.datetime :captured_at
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.references :uploaded_by, null: true, foreign_key: { to_table: :users }
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    create_table :incident_comments do |t|
      t.references :incident, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :comment, null: false
      t.string :comment_type, null: false, default: "note"
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    create_table :insurance_claims do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :claim_number, null: false
      t.string :policy_number
      t.string :insurer_name
      t.string :insurer_contact
      t.string :claim_type, null: false
      t.decimal :claimed_amount, precision: 12, scale: 2
      t.decimal :approved_amount, precision: 12, scale: 2
      t.decimal :deductible, precision: 12, scale: 2
      t.string :status, null: false, default: "draft"
      t.datetime :filed_at
      t.datetime :settled_at
      t.text :denial_reason
      t.text :settlement_notes
      t.references :filed_by, null: true, foreign_key: { to_table: :users }
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :insurance_claims, :claim_number, unique: true

    create_table :compliance_requirements do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :category, null: false
      t.string :applies_to, null: false
      t.text :description
      t.string :regulation_reference
      t.string :jurisdiction
      t.string :enforcement_level, null: false, default: "mandatory"
      t.string :check_type, null: false
      t.string :check_frequency
      t.boolean :auto_check, null: false, default: true
      t.jsonb :auto_check_config, null: false, default: {}
      t.string :penalty_description
      t.boolean :is_active, null: false, default: true
      t.integer :priority, null: false, default: 100
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :compliance_requirements, :code, unique: true
    add_index :compliance_requirements, :category
    add_index :compliance_requirements, :applies_to
    add_index :compliance_requirements, :is_active

    create_table :compliance_checks do |t|
      t.references :compliance_requirement, null: false, foreign_key: true
      t.string :checkable_type, null: false
      t.bigint :checkable_id, null: false
      t.references :trip, null: true, foreign_key: true
      t.string :result, null: false
      t.datetime :checked_at, null: false
      t.string :checked_by
      t.jsonb :details, null: false, default: {}
      t.text :notes
      t.datetime :expires_at

      t.timestamps
    end
    add_index :compliance_checks, [:checkable_type, :checkable_id]
    add_index :compliance_checks, :result
    add_index :compliance_checks, :checked_at

    create_table :compliance_violations do |t|
      t.string :violation_number, null: false
      t.references :compliance_requirement, null: false, foreign_key: true
      t.references :compliance_check, null: false, foreign_key: true
      t.string :violatable_type, null: false
      t.bigint :violatable_id, null: false
      t.references :trip, null: true, foreign_key: true
      t.string :severity, null: false
      t.string :status, null: false, default: "open"
      t.text :description
      t.text :required_action
      t.datetime :deadline
      t.datetime :resolved_at
      t.references :resolved_by, null: true, foreign_key: { to_table: :users }
      t.text :resolution_notes
      t.text :waiver_reason
      t.references :waiver_approved_by, null: true, foreign_key: { to_table: :users }
      t.datetime :waiver_expires_at
      t.decimal :financial_penalty, precision: 12, scale: 2
      t.references :linked_incident, null: true, foreign_key: { to_table: :incidents }
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :compliance_violations, :violation_number, unique: true
    add_index :compliance_violations, [:violatable_type, :violatable_id]
    add_index :compliance_violations, :status
    add_index :compliance_violations, :severity

    create_table :compliance_waivers do |t|
      t.references :compliance_violation, null: false, foreign_key: true
      t.string :waiver_number, null: false
      t.text :reason, null: false
      t.text :conditions
      t.text :risk_assessment
      t.references :approved_by, null: true, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.datetime :effective_from
      t.datetime :effective_until
      t.string :status, null: false, default: "pending"
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :compliance_waivers, :waiver_number, unique: true
    add_index :compliance_waivers, :status
  end
end
