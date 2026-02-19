require "sidekiq/api"

class Api::V1::Admin::SidekiqDashboardController < ApplicationController
  def show
    authorize :webhook_admin, :stats?

    stats = Sidekiq::Stats.new
    queue_sizes = Sidekiq::Queue.all.map { |q| [q.name, q.size] }.to_h
    processes = Sidekiq::ProcessSet.new

    render json: {
      overview: {
        processed: stats.processed,
        failed: stats.failed,
        busy: stats.workers_size,
        enqueued: stats.enqueued,
        scheduled: stats.scheduled_size,
        retries: stats.retry_size,
        dead: stats.dead_size,
        processes: processes.size,
        default_latency_seconds: stats.default_queue_latency
      },
      queues: queue_sizes,
      process_details: processes.map do |p|
        {
          hostname: p["hostname"],
          pid: p["pid"],
          concurrency: p["concurrency"],
          busy: p["busy"],
          queues: p["queues"],
          tag: p["tag"],
          labels: p["labels"],
          started_at: p["started_at"]
        }
      end
    }
  end
end
