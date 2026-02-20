class Compliance::DashboardController < ApplicationController
  def show
    authorize ComplianceViolation, :dashboard?

    checks = ComplianceCheck.all
    violations = ComplianceViolation.all
    vehicle_docs = VehicleDocument.where("expires_at <= ?", 30.days.from_now.to_date).count
    driver_docs = DriverDocument.where("expires_at <= ?", 30.days.from_now.to_date).count

    render json: {
      fleet_compliance_rate: fleet_compliance_rate(checks),
      vehicles_fully_compliant: compliant_vehicle_count,
      vehicles_with_issues: vehicles_with_issues_count,
      drivers_fully_compliant: compliant_driver_count,
      drivers_with_issues: drivers_with_issues_count,
      open_violations: violations.where(status: %w[open acknowledged remediation_in_progress escalated]).count,
      critical_violations: violations.where(severity: "critical").count,
      active_waivers: ComplianceWaiver.where(status: "approved").where("effective_until >= ?", Time.current).count,
      expiring_documents_30d: {
        vehicle_documents: vehicle_docs,
        driver_documents: driver_docs
      },
      compliance_by_category: category_breakdown,
      recent_violations: violations.order(created_at: :desc).limit(10).map { |violation| { id: violation.id, violation_number: violation.violation_number, severity: violation.severity, status: violation.status, created_at: violation.created_at } },
      upcoming_expirations: upcoming_expirations
    }
  end

  private

  def fleet_compliance_rate(checks)
    total = checks.count
    return 100.0 if total.zero?

    compliant = checks.where(result: "compliant").count
    ((compliant.to_f / total) * 100).round(1)
  end

  def compliant_vehicle_count
    vehicle_ids = Vehicle.pluck(:id)
    failed_ids = ComplianceViolation.where(violatable_type: "Vehicle", status: %w[open acknowledged remediation_in_progress escalated]).pluck(:violatable_id).uniq
    vehicle_ids.count - failed_ids.count
  end

  def vehicles_with_issues_count
    ComplianceViolation.where(violatable_type: "Vehicle", status: %w[open acknowledged remediation_in_progress escalated]).distinct.count(:violatable_id)
  end

  def compliant_driver_count
    driver_ids = User.where(role: :driver).pluck(:id)
    failed_ids = ComplianceViolation.where(violatable_type: "User", status: %w[open acknowledged remediation_in_progress escalated]).pluck(:violatable_id).uniq
    driver_ids.count - failed_ids.count
  end

  def drivers_with_issues_count
    ComplianceViolation.where(violatable_type: "User", status: %w[open acknowledged remediation_in_progress escalated]).distinct.count(:violatable_id)
  end

  def category_breakdown
    ComplianceRequirement.group(:category).each_with_object({}) do |(category, _), out|
      req_ids = ComplianceRequirement.where(category: category).pluck(:id)
      total = ComplianceCheck.where(compliance_requirement_id: req_ids).count
      compliant = ComplianceCheck.where(compliance_requirement_id: req_ids, result: "compliant").count
      non_compliant = ComplianceCheck.where(compliance_requirement_id: req_ids, result: "non_compliant").count

      out[category] = { compliant: compliant, non_compliant: non_compliant, total: total }
    end
  end

  def upcoming_expirations
    vehicle = VehicleDocument.where("expires_at BETWEEN ? AND ?", Date.current, 30.days.from_now.to_date).order(expires_at: :asc).limit(20).map do |doc|
      { type: "vehicle", id: doc.id, document_type: doc.document_type, expires_at: doc.expires_at, vehicle_id: doc.vehicle_id }
    end

    driver = DriverDocument.where("expires_at BETWEEN ? AND ?", Date.current, 30.days.from_now.to_date).order(expires_at: :asc).limit(20).map do |doc|
      { type: "driver", id: doc.id, document_type: doc.document_type, expires_at: doc.expires_at, driver_profile_id: doc.driver_profile_id }
    end

    (vehicle + driver).sort_by { |item| item[:expires_at] }
  end
end
