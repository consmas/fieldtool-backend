class FuelOmcBalance < ApplicationRecord
  OMC_NAMES = %w[westport top_oil other].freeze

  has_many :ledger_entries, class_name: "FuelOmcLedgerEntry", dependent: :destroy

  validates :omc_name, inclusion: { in: OMC_NAMES }, uniqueness: true
  # Balance can go negative when fuel expenses exceed deposits (overdraft mode).
  validates :balance, numericality: true
  validates :currency, presence: true
end
