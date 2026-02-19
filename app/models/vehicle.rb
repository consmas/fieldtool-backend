class Vehicle < ApplicationRecord
  enum :kind, { truck: 0, trailer: 1 }

  has_many :trips, dependent: :nullify
  has_many :expense_entries, dependent: :nullify
  has_many :maintenance_schedules, dependent: :destroy
  has_many :work_orders, dependent: :destroy
  has_many :vehicle_documents, dependent: :destroy
  has_many :fuel_logs, dependent: :destroy
  has_many :fuel_analysis_records, dependent: :destroy
  has_one_attached :insurance_document

  validates :name, presence: true
  validates :kind, presence: true
end
