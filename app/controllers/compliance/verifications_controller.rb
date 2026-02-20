class Compliance::VerificationsController < ApplicationController
  def create
    trip = Trip.find(params[:trip_id])
    authorize trip, :change_status?

    result = ComplianceGateService.check_trip_readiness(trip)

    audit(action: "compliance.audit_completed", auditable: trip, metadata: { ready: result[:ready], blocking: result[:blocking_failures].size, warnings: result[:warnings].size })

    render json: result
  end
end
