require "sidekiq"
require "sidekiq/web"
require "sidekiq/cron/job"

redis_url = ENV.fetch("SIDEKIQ_REDIS_URL", ENV.fetch("REDIS_URL", "redis://redis:6379/1"))

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  schedule_file = Rails.root.join("config/sidekiq_schedule.yml")
  Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file)) if File.exist?(schedule_file)

  config.error_handlers << proc do |ex, ctx, _config|
    FailedJob.create!(
      job_class: ctx.dig("class") || "SidekiqJob",
      queue_name: ctx.dig("queue"),
      arguments: Array(ctx.dig("args")),
      error_class: ex.class.name,
      error_message: ex.message.to_s.truncate(500),
      backtrace: Array(ex.backtrace).first(20).join("\n"),
      status: "failed",
      failed_at: Time.current,
      context: "sidekiq_global"
    )
  rescue StandardError
    Rails.logger.error("Failed to persist Sidekiq error record")
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
