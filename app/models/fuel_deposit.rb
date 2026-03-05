class FuelDeposit < ApplicationRecord
  OMC_NAMES = %w[westport top_oil other].freeze
  PAYMENT_METHODS = %w[bank_transfer momo cash cheque].freeze
  STATUSES = %w[draft confirmed cancelled].freeze

  belongs_to :creator, class_name: "User", foreign_key: :created_by_id
  belongs_to :confirmer, class_name: "User", foreign_key: :confirmed_by_id, optional: true

  has_one_attached :receipt

  validates :omc_name, inclusion: { in: OMC_NAMES }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :status, inclusion: { in: STATUSES }
  validates :amount, numericality: { greater_than: 0 }
  validates :deposit_date, presence: true
  validates :currency, presence: true

  scope :for_omc, ->(omc) { where(omc_name: omc) if omc.present? }
  scope :for_status, ->(status) { where(status: status) if status.present? }
end
