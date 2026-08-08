class OperationRecord < ApplicationRecord
  validates :record_type, presence: true
  validates :entry_date, presence: true

  scope :by_type, ->(type) { where(record_type: type) }
  scope :for_month, ->(month) { where(reporting_month: month) }
  scope :for_truck, ->(truck_id) { where(truck_id: truck_id) }
  scope :for_driver, ->(driver_name) { where(driver_name: driver_name) }

  def self.record_types
    %w[trip fleet driver compliance incident payment kpi summary]
  end
end
