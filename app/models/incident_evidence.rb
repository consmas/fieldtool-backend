class IncidentEvidence < ApplicationRecord
  EVIDENCE_TYPES = %w[photo video document audio diagram].freeze
  CATEGORIES = %w[scene vehicle_damage cargo_damage road_conditions police_report medical_report insurance_form witness_statement dashcam other].freeze

  belongs_to :incident
  belongs_to :uploader, class_name: "User", foreign_key: :uploaded_by, optional: true

  has_one_attached :file

  validates :evidence_type, inclusion: { in: EVIDENCE_TYPES }
  validates :category, inclusion: { in: CATEGORIES }
end
