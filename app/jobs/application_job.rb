class ApplicationJob < ActiveJob::Base
  around_perform do |job, block|
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    Rails.logger.info("[JobStart] #{job.class.name} queue=#{job.queue_name} args=#{job.arguments.inspect}")
    block.call
    elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
    Rails.logger.info("[JobDone] #{job.class.name} queue=#{job.queue_name} duration_ms=#{elapsed_ms}")
  rescue StandardError => e
    elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
    Rails.logger.error("[JobError] #{job.class.name} queue=#{job.queue_name} duration_ms=#{elapsed_ms} error=#{e.class}: #{e.message}")
    FailedJob.create!(
      job_class: job.class.name,
      queue_name: job.queue_name,
      arguments: job.arguments,
      error_class: e.class.name,
      error_message: e.message.to_s.truncate(500),
      backtrace: Array(e.backtrace).first(20).join("\n"),
      status: "failed",
      failed_at: Time.current
    )
    raise
  end
end
