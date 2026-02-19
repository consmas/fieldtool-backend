module WorkOrders
  class PartsController < ApplicationController
    before_action :set_work_order

    def create
      authorize @work_order, :parts?

      part = @work_order.parts.create!(part_params)
      render json: part_payload(part), status: :created
    end

    def update
      authorize @work_order, :parts?

      part = @work_order.parts.find(params[:id])
      part.update!(part_params)
      render json: part_payload(part)
    end

    def destroy
      authorize @work_order, :parts?

      part = @work_order.parts.find(params[:id])
      part.destroy!
      head :no_content
    end

    private

    def set_work_order
      @work_order = WorkOrder.find(params[:work_order_id])
    end

    def part_params
      params.require(:part).permit(:part_name, :part_number, :quantity, :unit, :unit_cost, :supplier, :notes)
    end

    def part_payload(part)
      {
        id: part.id,
        work_order_id: part.work_order_id,
        part_name: part.part_name,
        part_number: part.part_number,
        quantity: part.quantity,
        unit: part.unit,
        unit_cost: part.unit_cost,
        total_cost: part.total_cost,
        supplier: part.supplier,
        notes: part.notes
      }
    end
  end
end
