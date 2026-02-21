class Reports::ComplianceController < ApplicationController
  before_action :ensure_compliance_schema!

  def index
    authorize ComplianceViolation, :reports?

    violations = ComplianceViolation.all

    render json: {
      summary: {
        total_requirements: ComplianceRequirement.active.count,
        total_checks: ComplianceCheck.count,
        compliance_rate_pct: compliance_rate,
        open_violations: violations.where(status: %w[open acknowledged remediation_in_progress escalated]).count,
        resolved_violations: violations.where(status: "resolved").count,
        waivers_count: ComplianceWaiver.where(status: "approved").count
      },
      by_category: ComplianceRequirement.group(:category).count,
      violations_by_category: violations.joins(:compliance_requirement).group("compliance_requirements.category").count,
      violations_by_severity: violations.group(:severity).count,
      resolution_time_days: average_resolution_days(violations),
      most_common_violations: violations.group(:compliance_requirement_id).order(Arel.sql("COUNT(*) DESC")).limit(10).count,
      document_expiry_forecast_90d: {
        vehicle_documents: VehicleDocument.where("expires_at BETWEEN ? AND ?", Date.current, 90.days.from_now.to_date).count,
        driver_documents: DriverDocument.where("expires_at BETWEEN ? AND ?", Date.current, 90.days.from_now.to_date).count
      }
    }
  rescue ActiveRecord::StatementInvalid => e
    render json: { error: "Compliance report query failed", detail: e.message }, status: :service_unavailable
  end

  private

  def ensure_compliance_schema!
    required_tables = %w[
      compliance_requirements
      compliance_checks
      compliance_violations
      compliance_waivers
      vehicle_documents
      driver_documents
    ]
    missing = required_tables.reject { |table| ActiveRecord::Base.connection.data_source_exists?(table) }
    return if missing.empty?

    render json: { error: "Compliance module is not migrated yet", missing_tables: missing }, status: :service_unavailable
  end

  def compliance_rate
    total = ComplianceCheck.count
    return 100.0 if total.zero?

    compliant = ComplianceCheck.where(result: "compliant").count
    ((compliant.to_f / total) * 100).round(1)
  end

  def average_resolution_days(violations)
    resolved = violations.where.not(resolved_at: nil)
    return 0.0 if resolved.none?

    resolved.average("EXTRACT(EPOCH FROM (resolved_at - created_at)) / 86400.0").to_d.round(2)
  end
end
