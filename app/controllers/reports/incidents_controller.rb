class Reports::IncidentsController < ApplicationController
  def index
    authorize Incident, :reports?

    incidents = Incident.all
    claims = InsuranceClaim.all

    render json: {
      summary: {
        total_incidents: incidents.count,
        open_incidents: incidents.where(status: %w[reported acknowledged investigating reopened]).count,
        by_type: incidents.group(:incident_type).count,
        by_severity: incidents.group(:severity).count,
        root_cause_distribution: incidents.where.not(root_cause_category: nil).group(:root_cause_category).count
      },
      costs: {
        estimated_damage_cost: incidents.sum(:estimated_damage_cost).to_d,
        actual_damage_cost: incidents.sum(:actual_damage_cost).to_d,
        claimed_amount: claims.sum(:claimed_amount).to_d,
        approved_amount: claims.sum(:approved_amount).to_d
      },
      insurance: {
        by_status: claims.group(:status).count,
        success_rate_pct: insurance_success_rate(claims)
      },
      resolution: {
        average_resolution_days: resolution_days(incidents)
      },
      by_vehicle: incidents.group(:vehicle_id).count,
      by_driver: incidents.group(:driver_id).count
    }
  end

  private

  def insurance_success_rate(claims)
    settled = claims.where(status: %w[approved partially_approved settled]).count
    total = claims.count
    return 0.0 if total.zero?

    ((settled.to_f / total) * 100).round(1)
  end

  def resolution_days(incidents)
    resolved = incidents.where(status: %w[resolved closed]).where.not(created_at: nil, resolved_at: nil)
    return 0.0 if resolved.none?

    resolved.average("EXTRACT(EPOCH FROM (resolved_at - created_at)) / 86400.0").to_d.round(2)
  end
end
