class FuelOmcLedgerEntry < ApplicationRecord
  ENTRY_TYPES = %w[credit debit adjustment].freeze

  belongs_to :fuel_omc_balance
  belongs_to :reference, polymorphic: true, optional: true
  belongs_to :actor, class_name: "User", optional: true

  validates :entry_type, inclusion: { in: ENTRY_TYPES }
  validates :amount, numericality: { greater_than: 0 }
  validates :balance_before, numericality: true
  validates :balance_after, numericality: true
end
