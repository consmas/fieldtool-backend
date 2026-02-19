class WorkOrderPart < ApplicationRecord
  belongs_to :work_order

  validates :part_name, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }

  before_validation :compute_total_cost
  after_commit :sync_work_order_costs

  private

  def compute_total_cost
    self.total_cost = quantity.to_d * unit_cost.to_d
  end

  def sync_work_order_costs
    work_order.update!(parts_cost: work_order.parts.sum(:total_cost).to_d, actual_cost: work_order.labor_cost.to_d + work_order.parts.sum(:total_cost).to_d)
  end
end
