class Vehicle < ApplicationRecord
  enum :kind, { truck: 0, trailer: 1 }

  has_many :truck_trips, class_name: "Trip", foreign_key: :truck_id, inverse_of: :truck, dependent: :nullify
  has_many :trailer_trips, class_name: "Trip", foreign_key: :trailer_id, inverse_of: :trailer, dependent: :nullify

  validates :name, presence: true
  validates :kind, presence: true
end
