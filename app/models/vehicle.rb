class Vehicle < ApplicationRecord
  enum :kind, { truck: 0, trailer: 1 }

  has_many :trips, dependent: :nullify
  has_many :expense_entries, dependent: :nullify

  validates :name, presence: true
  validates :kind, presence: true
end
