class CreateNotificationEngine < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, null: true, foreign_key: { to_table: :users }
      t.string :notification_type, null: false
      t.string :category, null: false
      t.string :title, null: false
      t.text :body
      t.string :priority, null: false, default: "normal"
      t.string :notifiable_type
      t.bigint :notifiable_id
      t.string :action_url
      t.string :action_type
      t.jsonb :data, null: false, default: {}
      t.datetime :read_at
      t.datetime :seen_at
      t.datetime :archived_at
      t.string :delivered_via, null: false, default: [], array: true
      t.datetime :expires_at
      t.string :group_key

      t.timestamps
    end
    add_index :notifications, :read_at
    add_index :notifications, :category
    add_index :notifications, :notification_type
    add_index :notifications, [:notifiable_type, :notifiable_id]
    add_index :notifications, :group_key
    add_index :notifications, :priority

    create_table :notification_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.string :notification_type, null: false
      t.boolean :in_app, null: false, default: true
      t.boolean :push, null: false, default: false
      t.boolean :sms, null: false, default: false
      t.boolean :email, null: false, default: false
      t.boolean :is_enabled, null: false, default: true
      t.time :quiet_hours_start
      t.time :quiet_hours_end

      t.timestamps
    end
    add_index :notification_preferences, [:user_id, :notification_type], unique: true, name: "index_notification_prefs_user_type"

    create_table :device_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.string :platform, null: false
      t.string :device_name
      t.boolean :is_active, null: false, default: true
      t.datetime :last_used_at

      t.timestamps
    end
    add_index :device_tokens, :token, unique: true
    add_index :device_tokens, :is_active

    create_table :escalation_rules do |t|
      t.string :name, null: false
      t.string :trigger_event, null: false
      t.string :condition_type, null: false
      t.integer :condition_minutes, null: false
      t.integer :escalation_level, null: false, default: 1
      t.string :escalate_to_role
      t.references :escalate_to_user, null: true, foreign_key: { to_table: :users }
      t.string :escalation_channels, null: false, default: [], array: true
      t.string :escalation_priority, null: false, default: "high"
      t.string :escalation_message
      t.integer :max_escalations, null: false, default: 3
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end
    add_index :escalation_rules, :trigger_event
    add_index :escalation_rules, :is_active

    create_table :escalation_instances do |t|
      t.references :escalation_rule, null: false, foreign_key: true
      t.references :notification, null: false, foreign_key: true
      t.string :notifiable_type
      t.bigint :notifiable_id
      t.integer :current_level, null: false, default: 0
      t.string :status, null: false, default: "active"
      t.datetime :last_escalated_at
      t.datetime :resolved_at
      t.references :resolved_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :escalation_instances, :status
    add_index :escalation_instances, [:notifiable_type, :notifiable_id], name: "index_escalation_instances_notifiable"
  end
end
