module Maintenance
  class VendorsController < ApplicationController
    def index
      authorize MaintenanceVendor, :index?

      scope = MaintenanceVendor.all
      scope = scope.where("specializations @> ARRAY[?]::varchar[]", params[:specialization]) if params[:specialization].present?
      scope = scope.where(city: params[:city]) if params[:city].present?
      scope = scope.where(is_active: cast_bool(params[:is_active])) unless params[:is_active].nil?
      scope = scope.where("rating >= ?", params[:rating].to_d) if params[:rating].present?

      data = scope.order(name: :asc).map do |vendor|
        {
          id: vendor.id,
          name: vendor.name,
          contact_name: vendor.contact_name,
          phone: vendor.phone,
          email: vendor.email,
          city: vendor.city,
          specializations: vendor.specializations,
          rating: vendor.rating,
          is_active: vendor.is_active,
          work_order_count: vendor.work_orders.count,
          total_spend: vendor.work_orders.sum(:actual_cost).to_d,
          average_rating: vendor.rating
        }
      end

      render json: { data: data }
    end

    def create
      authorize MaintenanceVendor, :create?

      vendor = MaintenanceVendor.create!(vendor_params)
      render json: vendor_payload(vendor), status: :created
    end

    def show
      vendor = MaintenanceVendor.find(params[:id])
      authorize vendor, :show?

      render json: vendor_payload(vendor).merge(
        work_orders: vendor.work_orders.order(created_at: :desc).limit(50).map do |wo|
          {
            id: wo.id,
            work_order_number: wo.work_order_number,
            title: wo.title,
            status: wo.status,
            actual_cost: wo.actual_cost,
            completed_at: wo.completed_at
          }
        end
      )
    end

    def update
      vendor = MaintenanceVendor.find(params[:id])
      authorize vendor, :update?

      vendor.update!(vendor_params)
      render json: vendor_payload(vendor)
    end

    private

    def vendor_params
      params.require(:vendor).permit(:name, :contact_name, :phone, :email, :address, :city, :rating, :is_active, :notes, metadata: {}, specializations: [])
    end

    def vendor_payload(vendor)
      {
        id: vendor.id,
        name: vendor.name,
        contact_name: vendor.contact_name,
        phone: vendor.phone,
        email: vendor.email,
        address: vendor.address,
        city: vendor.city,
        specializations: vendor.specializations,
        rating: vendor.rating,
        is_active: vendor.is_active,
        notes: vendor.notes,
        metadata: vendor.metadata
      }
    end

    def cast_bool(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
