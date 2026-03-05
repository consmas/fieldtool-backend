class FuelOmcBalance < ApplicationRecord
  OMC_NAMES = %w[westport top_oil other].freeze

  has_many :ledger_entries, class_name: "FuelOmcLedgerEntry", dependent: :destroy

  validates :omc_name, inclusion: { in: OMC_NAMES }, uniqueness: true
  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
end
