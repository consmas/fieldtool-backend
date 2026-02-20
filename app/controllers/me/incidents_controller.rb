class Me::IncidentsController < ApplicationController
  def index
    authorize Incident, :my_incidents?

    incidents = Incident.where(driver_id: current_user.id).order(incident_date: :desc)
    render json: {
      data: incidents.limit(200).map do |incident|
        {
          id: incident.id,
          incident_number: incident.incident_number,
          trip_id: incident.trip_id,
          incident_type: incident.incident_type,
          severity: incident.severity,
          status: incident.status,
          title: incident.title,
          incident_date: incident.incident_date
        }
      end
    }
  end

  def create
    authorize Incident, :my_incidents?

    trip = Trip.find(params[:trip_id])
    unless trip.driver_id == current_user.id
      return render json: { error: "Trip does not belong to current driver" }, status: :forbidden
    end

    incident = Incident.new(driver_incident_params)
    incident.trip = trip
    incident.vehicle_id ||= trip.vehicle_id
    incident.driver = current_user
    incident.reporter = current_user
    incident.incident_date ||= Time.current
    incident.status = "reported"
    set_audit_actor(incident)
    incident.save!

    NotificationService.notify(
      notification_type: "system.announcement",
      recipients: ["dispatcher", "supervisor"],
      actor: current_user,
      notifiable: incident,
      priority: "high",
      data: { title: "Driver Incident Report", message: "#{incident.incident_number} - #{incident.title}" }
    )

    audit(action: "incident.created", auditable: incident, metadata: { source: "driver_mobile" })

    render json: { id: incident.id, incident_number: incident.incident_number, status: incident.status }, status: :created
  end

  def create_evidence
    incident = Incident.find(params[:id])
    authorize incident, :my_incidents?

    unless incident.driver_id == current_user.id
      return render json: { error: "Incident does not belong to current driver" }, status: :forbidden
    end

    evidence = incident.evidence_items.new(evidence_type: params[:evidence_type] || "photo", category: params[:category] || "scene", title: params[:title])
    evidence.uploader = current_user
    evidence.file.attach(params.require(:file))
    evidence.save!

    audit(action: "incident.evidence_added", auditable: incident, associated: evidence, metadata: { source: "driver_mobile" })

    render json: { id: evidence.id, category: evidence.category }, status: :created
  end

  private

  def driver_incident_params
    params.permit(
      :trip_id, :vehicle_id, :incident_type, :severity, :title, :description,
      :incident_location, :latitude, :longitude, :injuries_reported, :vehicle_drivable,
      :towing_required, metadata: {}
    )
  end
end
