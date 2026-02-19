module Reports
  class ScheduledReportJob < ApplicationJob
    queue_as :low

    def perform
      # Placeholder weekly fleet report generation trigger.
      admin_ids = User.where(role: [:admin, :finance, :supervisor]).pluck(:id)
      admin_ids.each do |id|
        Reports::GenerateReportJob.perform_later(report_type: "weekly_fleet_summary", requested_by_id: id, params: {})
      end
    end
  end
end
