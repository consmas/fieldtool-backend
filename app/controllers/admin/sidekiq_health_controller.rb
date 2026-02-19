require "sidekiq/api"

class Admin::SidekiqHealthController < ApplicationController
  def show
    authorize :webhook_admin, :stats?

    redis_url = ENV.fetch("SIDEKIQ_REDIS_URL", ENV.fetch("REDIS_URL", "redis://redis:6379/1"))
    redis = Redis.new(url: redis_url)
    ping = redis.ping

    process_count = Sidekiq::ProcessSet.new.size
    queue_sizes = Sidekiq::Queue.all.map { |q| [q.name, q.size] }.to_h

    render json: {
      status: (ping == "PONG" && process_count.positive?) ? "ok" : "degraded",
      redis: ping,
      process_count: process_count,
      queues: queue_sizes,
      checked_at: Time.current
    }
  rescue StandardError => e
    render json: { status: "error", error: e.message }, status: :service_unavailable
  end
end
