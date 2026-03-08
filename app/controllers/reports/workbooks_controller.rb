class Reports::WorkbooksController < ApplicationController
  def monitoring_workbook
    authorize :fleet_report, :show?

    exporter = exporter_service
    if xlsx_request?
      send_data(
        exporter.monitoring_workbook_xlsx,
        filename: "consmas_monthly_monitoring_#{report_month.strftime('%Y_%m')}.xlsx",
        type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
      return
    end

    if csv_request?
      send_data(
        exporter.monitoring_workbook_csv(sheet_key: params[:sheet].to_s),
        filename: "consmas_monitoring_#{report_month.strftime('%Y_%m')}.csv",
        type: "text/csv"
      )
      return
    end

    render json: {
      report_month: report_month.strftime("%Y-%m"),
      export_links: export_links("monitoring_workbook")
    }
  end

  def monitoring_regime
    authorize :fleet_report, :show?

    exporter = exporter_service
    if xlsx_request?
      send_data(
        exporter.reporting_regime_xlsx,
        filename: "consmas_reporting_regime_#{report_month.year}.xlsx",
        type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
      return
    end

    render json: {
      report_year: report_month.year,
      export_links: export_links("monitoring_regime")
    }
  end

  def budget_workbook
    authorize :fleet_report, :show?

    exporter = exporter_service
    if xlsx_request?
      send_data(
        exporter.budget_workbook_xlsx,
        filename: "fleet_operations_budget_#{report_month.strftime('%Y_%m')}.xlsx",
        type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
      return
    end

    render json: {
      report_month: report_month.strftime("%Y-%m"),
      export_links: export_links("budget_workbook")
    }
  end

  private

  def report_month
    @report_month ||= begin
      value = params[:month].presence || params[:reporting_month].presence
      value.present? ? Date.strptime(value, "%Y-%m").to_time.in_time_zone.beginning_of_month : Time.current.beginning_of_month
    rescue ArgumentError
      Time.current.beginning_of_month
    end
  end

  def exporter_service
    Reports::WorkbookExportService.new(month: report_month, prepared_by: current_user&.name || "System")
  end

  def xlsx_request?
    params[:format].to_s == "xlsx" || params[:export].to_s == "xlsx"
  end

  def csv_request?
    params[:format].to_s == "csv" || params[:export].to_s == "csv"
  end

  def export_links(endpoint)
    {
      xlsx: "/api/v1/reports/#{endpoint}?month=#{report_month.strftime('%Y-%m')}&export=xlsx",
      csv: "/api/v1/reports/#{endpoint}?month=#{report_month.strftime('%Y-%m')}&export=csv"
    }
  end
end
