require "sidekiq/api"

class Admin::SidekiqDashboardController < ActionController::Base
  before_action :http_basic_auth

  def show
    @stats = Sidekiq::Stats.new
    @queues = Sidekiq::Queue.all.index_by(&:name)
    @processes = Sidekiq::ProcessSet.new
    @selected_set = params[:set].presence || "enqueued"
    @selected_queue = params[:queue].presence
    @limit = [[params.fetch(:limit, 50).to_i, 1].max, 200].min
    @history = Sidekiq::Stats::History.new(30)
    @failed_job_records = FailedJob.order(failed_at: :desc).limit(@limit)

    @job_rows = load_job_rows
    @selected_job = load_selected_job
  end

  private

  def load_job_rows
    case @selected_set
    when "enqueued"
      queue_name = @selected_queue || @queues.keys.first
      return [] if queue_name.blank?

      Sidekiq::Queue.new(queue_name).first(@limit).map { |job| format_job(job, source: "queue:#{queue_name}") }
    when "retries"
      Sidekiq::RetrySet.new.first(@limit).map { |job| format_job(job, source: "retry") }
    when "scheduled"
      Sidekiq::ScheduledSet.new.first(@limit).map { |job| format_job(job, source: "scheduled") }
    when "dead"
      Sidekiq::DeadSet.new.first(@limit).map { |job| format_job(job, source: "dead") }
    when "busy"
      Sidekiq::Workers.new.map do |_process_id, _thread_id, work|
        payload = work["payload"] || {}
        {
          jid: payload["jid"],
          klass: payload["class"],
          queue: payload["queue"],
          args: payload["args"],
          enqueued_at: payload["enqueued_at"],
          run_at: work["run_at"],
          source: "busy",
          payload: payload
        }
      end.first(@limit)
    when "failed_records"
      @failed_job_records.map do |row|
        {
          jid: nil,
          klass: row.job_class,
          queue: row.queue_name,
          args: row.arguments,
          enqueued_at: row.created_at,
          run_at: row.failed_at,
          source: "failed_record",
          error_class: row.error_class,
          error_message: row.error_message,
          payload: row.attributes
        }
      end
    else
      []
    end
  end

  def load_selected_job
    jid = params[:jid].presence
    return nil if jid.blank?

    @job_rows.find { |j| j[:jid].to_s == jid.to_s }
  end

  def format_job(job, source:)
    item = job.item
    {
      jid: job.jid,
      klass: item["wrapped"] || item["class"],
      queue: item["queue"],
      args: item["args"],
      enqueued_at: item["enqueued_at"] ? Time.at(item["enqueued_at"]).utc : nil,
      run_at: (item["at"] ? Time.at(item["at"]).utc : nil),
      retries: item["retry_count"],
      error_class: item["error_class"],
      error_message: item["error_message"],
      source: source,
      payload: item
    }
  end

  def http_basic_auth
    username = ENV["SIDEKIQ_ADMIN_USER"].presence
    password = ENV["SIDEKIQ_ADMIN_PASSWORD"].presence
    return if username.blank? || password.blank?

    authenticate_or_request_with_http_basic("Sidekiq Dashboard") do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user, username) &
        ActiveSupport::SecurityUtils.secure_compare(pass, password)
    end
  end
end
