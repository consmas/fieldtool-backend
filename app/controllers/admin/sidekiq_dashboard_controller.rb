require "sidekiq/api"

class Admin::SidekiqDashboardController < ActionController::Base
  before_action :http_basic_auth
  skip_forgery_protection

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
    @workers = Sidekiq::Workers.new.map do |process_id, thread_id, work|
      payload = work["payload"] || {}
      {
        process_id: process_id,
        thread_id: thread_id,
        jid: payload["jid"],
        klass: payload["class"],
        queue: payload["queue"],
        run_at: work["run_at"],
        payload: payload
      }
    end
    @notice = params[:notice]
    @alert = params[:alert]
  end

  def job_action
    set = params[:set].to_s
    queue = params[:queue].to_s
    jid = params[:jid].to_s
    operation = params[:operation].to_s
    job = find_job(set:, queue:, jid:)

    return redirect_back_with_message("Job not found", level: :alert, set:, queue:) if job.nil?

    case operation
    when "retry"
      perform_retry(job)
      redirect_back_with_message("Job requeued", set:, queue:)
    when "delete"
      job.delete
      redirect_back_with_message("Job deleted", set:, queue:)
    when "kill"
      if job.respond_to?(:kill)
        job.kill
        redirect_back_with_message("Job moved to dead set", set:, queue:)
      else
        redirect_back_with_message("Kill not supported for this set", level: :alert, set:, queue:)
      end
    when "enqueue_now"
      if job.respond_to?(:add_to_queue)
        job.add_to_queue
        redirect_back_with_message("Job enqueued now", set:, queue:)
      else
        redirect_back_with_message("Enqueue now not supported for this set", level: :alert, set:, queue:)
      end
    else
      redirect_back_with_message("Unsupported operation", level: :alert, set:, queue:)
    end
  rescue StandardError => e
    redirect_back_with_message("Job action failed: #{e.message}", level: :alert, set:, queue:)
  end

  def queue_action
    queue_name = params[:queue].to_s
    operation = params[:operation].to_s
    queue = Sidekiq::Queue.new(queue_name)

    case operation
    when "clear"
      queue.clear
      redirect_to_sidekiq_dashboard(set: "enqueued", queue: queue_name, notice: "Queue #{queue_name} cleared")
    else
      redirect_to_sidekiq_dashboard(set: "enqueued", queue: queue_name, alert: "Unsupported queue operation")
    end
  rescue StandardError => e
    redirect_to_sidekiq_dashboard(set: "enqueued", queue: queue_name, alert: "Queue action failed: #{e.message}")
  end

  def process_action
    identity = params[:identity].to_s
    operation = params[:operation].to_s
    process = Sidekiq::ProcessSet.new.find { |p| p["identity"].to_s == identity }
    return redirect_to_sidekiq_dashboard(alert: "Process not found") if process.nil?

    case operation
    when "quiet"
      process.quiet!
      redirect_to_sidekiq_dashboard(notice: "Process #{identity} set to quiet")
    when "stop"
      process.stop!
      redirect_to_sidekiq_dashboard(notice: "Stop signal sent to process #{identity}")
    else
      redirect_to_sidekiq_dashboard(alert: "Unsupported process operation")
    end
  rescue StandardError => e
    redirect_to_sidekiq_dashboard(alert: "Process action failed: #{e.message}")
  end

  private

  def find_job(set:, queue:, jid:)
    case set
    when "enqueued" then Sidekiq::Queue.new(queue).find_job(jid)
    when "retries" then Sidekiq::RetrySet.new.find_job(jid)
    when "scheduled" then Sidekiq::ScheduledSet.new.find_job(jid)
    when "dead" then Sidekiq::DeadSet.new.find_job(jid)
    else nil
    end
  end

  def perform_retry(job)
    return job.retry if job.respond_to?(:retry)
    return job.add_to_queue if job.respond_to?(:add_to_queue)

    raise "Retry not supported for this set"
  end

  def redirect_back_with_message(message, level: :notice, set:, queue:)
    redirect_to_sidekiq_dashboard(set:, queue:, level => message)
  end

  def redirect_to_sidekiq_dashboard(set: params[:set], queue: params[:queue], notice: nil, alert: nil)
    redirect_to(
      "/admin/sidekiq-dashboard?" + {
        set: set.presence,
        queue: queue.presence,
        limit: @limit || params[:limit],
        notice: notice,
        alert: alert
      }.compact.to_query
    )
  end

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
