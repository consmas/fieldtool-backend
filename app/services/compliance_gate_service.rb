class ComplianceGateService
  def self.check_trip_readiness(trip)
    results = []

    ComplianceRequirement.active.where(applies_to: "vehicle").find_each do |requirement|
      results << evaluate_requirement(trip, requirement, trip.vehicle)
    end

    ComplianceRequirement.active.where(applies_to: "driver").find_each do |requirement|
      results << evaluate_requirement(trip, requirement, trip.driver)
    end

    ComplianceRequirement.active.where(applies_to: "trip").find_each do |requirement|
      results << evaluate_requirement(trip, requirement, trip)
    end

    pretrip_result = check_pre_trip_inspection(trip)
    results << pretrip_result if pretrip_result

    blocking_failures = results.select { |item| item[:result] == "non_compliant" && item[:blocking] }
    warnings = results.select { |item| item[:result] == "warning" }

    {
      ready: blocking_failures.empty?,
      results: results,
      blocking_failures: blocking_failures,
      warnings: warnings,
      checked_at: Time.current
    }
  end

  def self.evaluate_requirement(trip, requirement, resource)
    result = {
      requirement_id: requirement.id,
      code: requirement.code,
      name: requirement.name,
      result: "compliant",
      details: nil,
      blocking: false
    }

    config = requirement.auto_check_config || {}

    case config["type"]
    when "document_expiry"
      result = evaluate_document_expiry(resource, requirement, config, result)
    when "threshold"
      result = evaluate_threshold(trip, resource, requirement, config, result)
    else
      result = result.merge(result: "pending", details: "manual verification required") unless requirement.auto_check
    end

    persisted_trip = trip if trip&.persisted?

    check = ComplianceCheck.create!(
      compliance_requirement: requirement,
      checkable: resource,
      trip: persisted_trip,
      result: result[:result],
      checked_at: Time.current,
      checked_by: "system",
      details: result,
      notes: result[:details]
    )

    if result[:result] == "non_compliant"
      violation = ComplianceViolation.find_or_initialize_by(compliance_check: check)
      violation.assign_attributes(
        compliance_requirement: requirement,
        violatable: resource,
        trip: persisted_trip,
        severity: compliance_severity_for(requirement),
        status: "open",
        description: result[:details],
        required_action: "Resolve requirement: #{requirement.name}",
        deadline: compliance_deadline_for(requirement)
      )
      violation.save!

      AuditService.record(
        action: "compliance.violation_created",
        auditable: violation,
        associated: persisted_trip,
        metadata: { requirement_code: requirement.code, details: result[:details] }
      )
    end

    result
  rescue StandardError => e
    {
      requirement_id: requirement.id,
      code: requirement.code,
      name: requirement.name,
      result: "warning",
      details: "check failed: #{e.message}",
      blocking: false
    }
  end

  class << self
    private

    def evaluate_document_expiry(resource, _requirement, config, base)
      model_name = config["document_model"]
      document_type = config["document_type"]
      warn_days = config["warn_days_before"].to_i
      blocking = ActiveModel::Type::Boolean.new.cast(config["block_trip_if_expired"])

      document = find_latest_document(resource, model_name, document_type)
      return base.merge(result: "non_compliant", details: "missing #{document_type}", blocking: blocking) if document.nil?

      expires_at = document.try(:expires_at)
      return base.merge(result: "compliant", details: "no expiry") if expires_at.blank?

      if expires_at < Date.current
        base.merge(result: "non_compliant", details: "#{document_type} expired on #{expires_at}", blocking: blocking)
      elsif expires_at <= Date.current + warn_days.days
        base.merge(result: "warning", details: "#{document_type} expires on #{expires_at}", blocking: false)
      else
        base.merge(result: "compliant", details: "valid until #{expires_at}")
      end
    end

    def evaluate_threshold(trip, resource, _requirement, config, base)
      field = config["field"].to_s
      max_value = config["max_value"].to_d
      blocking = ActiveModel::Type::Boolean.new.cast(config["block_trip_if_exceeded"])

      candidate = if trip.respond_to?(field)
                    trip.public_send(field)
                  elsif resource.respond_to?(field)
                    resource.public_send(field)
                  end

      value = candidate.to_d
      return base.merge(result: "pending", details: "field #{field} unavailable") if candidate.nil?

      if max_value.positive? && value > max_value
        base.merge(result: "non_compliant", details: "#{field}=#{value} exceeds #{max_value}", blocking: blocking)
      else
        base.merge(result: "compliant", details: "#{field}=#{value}")
      end
    end

    def find_latest_document(resource, model_name, document_type)
      case model_name
      when "VehicleDocument"
        return nil unless resource.respond_to?(:vehicle_documents)

        resource.vehicle_documents.where(document_type: document_type).order(expires_at: :desc).first
      when "DriverDocument"
        profile = resource.respond_to?(:driver_profile) ? resource.driver_profile : nil
        return nil if profile.nil?

        profile.driver_documents.where(document_type: document_type).order(expires_at: :desc).first
      else
        nil
      end
    end

    def check_pre_trip_inspection(trip)
      requirement = ComplianceRequirement.active.find_by(code: "OP-001")
      return nil if requirement.nil?

      inspection = trip.pre_trip_inspection
      compliant = inspection.present? &&
        inspection.inspection_verification_status_approved? &&
        inspection.inspection_confirmed?
      result = {
        requirement_id: requirement.id,
        code: requirement.code,
        name: requirement.name,
        result: compliant ? "compliant" : "non_compliant",
        details: compliant ? "inspection completed" : "inspection missing or not confirmed",
        blocking: true
      }

      check = ComplianceCheck.create!(
        compliance_requirement: requirement,
        checkable: trip,
        trip: trip,
        result: result[:result],
        checked_at: Time.current,
        checked_by: "system",
        details: result,
        notes: result[:details]
      )

      return result if compliant

      ComplianceViolation.create!(
        compliance_requirement: requirement,
        compliance_check: check,
        violatable: trip,
        trip: trip,
        severity: "high",
        status: "open",
        description: result[:details],
        required_action: "Complete pre-trip inspection",
        deadline: Time.current + 4.hours
      )
      result
    end

    def compliance_severity_for(requirement)
      return "critical" if requirement.enforcement_level == "mandatory"

      requirement.enforcement_level == "recommended" ? "medium" : "low"
    end

    def compliance_deadline_for(requirement)
      requirement.enforcement_level == "mandatory" ? 24.hours.from_now : 72.hours.from_now
    end
  end
end
