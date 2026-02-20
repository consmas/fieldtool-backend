class Compliance::ChecksController < ApplicationController
  def index
    authorize ComplianceCheck, :index?

    scope = ComplianceCheck.includes(:compliance_requirement).order(checked_at: :desc)
    scope = scope.where(result: params[:result]) if params[:result].present?
    scope = scope.where(compliance_requirement_id: params[:requirement_id]) if params[:requirement_id].present?
    scope = scope.where(checkable_type: params[:checkable_type].to_s.classify) if params[:checkable_type].present?
    scope = scope.where(checkable_id: params[:checkable_id]) if params[:checkable_id].present?
    scope = scope.where(trip_id: params[:trip_id]) if params[:trip_id].present?

    render json: { data: serialized_checks(scope.limit(1000)) }
  end

  def vehicle
    authorize ComplianceCheck, :index?
    vehicle = Vehicle.find(params[:vehicle_id])
    scope = ComplianceCheck.where(checkable: vehicle).order(checked_at: :desc)
    render json: { vehicle_id: vehicle.id, data: serialized_checks(scope.limit(500)) }
  end

  def driver
    authorize ComplianceCheck, :index?
    driver = User.find(params[:driver_id])
    scope = ComplianceCheck.where(checkable: driver).order(checked_at: :desc)
    render json: { driver_id: driver.id, data: serialized_checks(scope.limit(500)) }
  end

  private

  def serialized_checks(scope)
    scope.map do |check|
      {
        id: check.id,
        compliance_requirement_id: check.compliance_requirement_id,
        requirement_code: check.compliance_requirement&.code,
        checkable_type: check.checkable_type,
        checkable_id: check.checkable_id,
        trip_id: check.trip_id,
        result: check.result,
        checked_at: check.checked_at,
        checked_by: check.checked_by,
        details: check.details,
        notes: check.notes,
        expires_at: check.expires_at
      }
    end
  end
end
