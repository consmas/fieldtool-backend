module Reports
  class MonthlyExpenseSummaryJob < ApplicationJob
    queue_as :low

    def perform
      Reports::GenerateReportJob.perform_later(report_type: "monthly_expense_summary", requested_by_id: User.where(role: :admin).limit(1).pick(:id), params: {})
    end
  end
end
