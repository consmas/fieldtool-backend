module Reports
  class GenerateReportJob < ApplicationJob
    queue_as :low

    def perform(report_type:, requested_by_id:, params: {})
      Rails.logger.info("[GenerateReportJob] type=#{report_type} requested_by_id=#{requested_by_id} params=#{params}")
    end
  end
end
