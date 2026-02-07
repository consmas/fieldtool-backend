class Vehicle < ApplicationRecord
  enum :kind, { truck: 0, trailer: 1 }

  has_many :trips, dependent: :nullify

  validates :name, presence: true
  validates :kind, presence: true
end
