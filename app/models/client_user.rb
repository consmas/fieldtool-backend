class ClientUser < ApplicationRecord
  ROLES = %w[admin viewer billing].freeze

  belongs_to :client
  has_secure_password

  validates :email, :name, presence: true
  validates :email, uniqueness: true
  validates :role, inclusion: { in: ROLES }
end
