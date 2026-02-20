class Incident < ApplicationRecord
  include Auditable

  INCIDENT_TYPES = %w[
    accident_collision accident_single_vehicle accident_pedestrian
    breakdown_engine breakdown_tire breakdown_transmission breakdown_electrical breakdown_brakes breakdown_other
    cargo_damage cargo_loss cargo_spill
    theft_vehicle theft_cargo theft_fuel
    fire road_hazard security_incident environmental driver_health traffic_violation near_miss property_damage other
  ].freeze
  SEVERITIES = %w[minor moderate major critical].freeze
  STATUSES = %w[reported acknowledged investigating resolved closed reopened].freeze
  ROOT_CAUSE_CATEGORIES = %w[driver_error mechanical_failure road_conditions weather third_party cargo_issue other].freeze

  belongs_to :trip, optional: true
  belongs_to :vehicle
  belongs_to :driver, class_name: "User"
  belongs_to :reporter, class_name: "User", foreign_key: :reported_by
  belongs_to :assigned_investigator, class_name: "User", optional: true
  belongs_to :resolver, class_name: "User", foreign_key: :resolved_by, optional: true

  has_many :witnesses, class_name: "IncidentWitness", dependent: :destroy, inverse_of: :incident
  has_many :evidence_items, class_name: "IncidentEvidence", dependent: :destroy, inverse_of: :incident
  has_many :comments, class_name: "IncidentComment", dependent: :destroy, inverse_of: :incident
  has_many :insurance_claims, dependent: :destroy, inverse_of: :incident

  validates :incident_number, presence: true, uniqueness: true
  validates :incident_type, inclusion: { in: INCIDENT_TYPES }
  validates :severity, inclusion: { in: SEVERITIES }
  validates :status, inclusion: { in: STATUSES }
  validates :title, :incident_date, presence: true
  validates :root_cause_category, inclusion: { in: ROOT_CAUSE_CATEGORIES }, allow_blank: true

  before_validation :assign_incident_number, on: :create

  scope :open_statuses, -> { where(status: %w[reported acknowledged investigating reopened]) }

  def can_transition_to?(new_status)
    rules = {
      "reported" => %w[acknowledged],
      "acknowledged" => %w[investigating],
      "investigating" => %w[resolved],
      "resolved" => %w[closed reopened],
      "closed" => %w[reopened],
      "reopened" => %w[investigating]
    }

    rules.fetch(status, []).include?(new_status.to_s)
  end

  def transition_status!(new_status:, actor:, notes: nil)
    new_status = new_status.to_s
    raise ArgumentError, "invalid status transition #{status} -> #{new_status}" unless can_transition_to?(new_status)

    attrs = { status: new_status }
    attrs[:investigation_started_at] = Time.current if new_status == "investigating" && investigation_started_at.blank?
    attrs[:resolved_at] = Time.current if new_status == "resolved"
    attrs[:resolved_by] = actor.id if new_status == "resolved"

    update!(attrs)
    comments.create!(user: actor, comment: notes.presence || "Status changed from #{status_before_last_save || status} to #{new_status}", comment_type: "status_change", metadata: { to_status: new_status })
  end

  private

  def assign_incident_number
    return if incident_number.present?

    year = Time.current.year
    sequence = (self.class.where("incident_number LIKE ?", "INC-#{year}-%").count + 1).to_s.rjust(4, "0")
    self.incident_number = "INC-#{year}-#{sequence}"
  end
end
