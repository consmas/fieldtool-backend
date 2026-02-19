class Client < ApplicationRecord
  CONTRACT_TYPES = %w[spot contract dedicated].freeze
  RATE_TYPES = %w[per_trip per_km per_ton fixed_monthly].freeze

  has_many :client_users, dependent: :destroy
  has_many :shipments, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :trips, dependent: :nullify

  validates :name, :code, presence: true
  validates :code, uniqueness: true
  validates :contract_type, inclusion: { in: CONTRACT_TYPES }, allow_blank: true
  validates :rate_type, inclusion: { in: RATE_TYPES }, allow_blank: true
end
