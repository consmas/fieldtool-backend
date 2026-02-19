class CreateWebhookSystemAndFailedJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint :organization_id
      t.string :url, null: false
      t.string :secret, null: false
      t.string :event_types, array: true, default: [], null: false
      t.boolean :is_active, null: false, default: true
      t.string :description
      t.jsonb :metadata, null: false, default: {}
      t.datetime :last_triggered_at
      t.integer :failure_count, null: false, default: 0
      t.datetime :disabled_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :webhook_subscriptions, :organization_id
    add_index :webhook_subscriptions, :is_active
    add_index :webhook_subscriptions, :event_types, using: :gin
    add_index :webhook_subscriptions, :deleted_at

    create_table :webhook_events do |t|
      t.string :event_type, null: false
      t.string :resource_type
      t.bigint :resource_id
      t.jsonb :payload, null: false, default: {}
      t.bigint :triggered_by

      t.timestamps
    end

    add_index :webhook_events, :event_type
    add_index :webhook_events, [:resource_type, :resource_id]
    add_index :webhook_events, :triggered_by

    create_table :webhook_deliveries do |t|
      t.references :webhook_subscription, null: false, foreign_key: true
      t.references :webhook_event, foreign_key: true
      t.string :event_type, null: false
      t.string :idempotency_key, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.integer :max_attempts, null: false, default: 5
      t.datetime :last_attempt_at
      t.datetime :next_retry_at
      t.integer :response_code
      t.text :response_body
      t.integer :response_duration_ms
      t.string :error_message
      t.datetime :delivered_at

      t.timestamps
    end

    add_index :webhook_deliveries, :status
    add_index :webhook_deliveries, :event_type
    add_index :webhook_deliveries, :idempotency_key, unique: true
    add_index :webhook_deliveries, :next_retry_at

    create_table :failed_jobs do |t|
      t.string :job_class, null: false
      t.string :queue_name
      t.jsonb :arguments, null: false, default: []
      t.string :error_class
      t.text :error_message
      t.text :backtrace
      t.string :status, null: false, default: "failed"
      t.string :context
      t.datetime :failed_at, null: false
      t.datetime :retried_at
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :failed_jobs, :job_class
    add_index :failed_jobs, :queue_name
    add_index :failed_jobs, :status
    add_index :failed_jobs, :failed_at
  end
end
