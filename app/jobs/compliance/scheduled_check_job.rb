module Compliance
  class ScheduledCheckJob < ApplicationJob
    queue_as :low

    def perform
      check_vehicle_documents
      check_driver_documents
    end

    private

    def check_vehicle_documents
      ComplianceRequirement.active.where(applies_to: "vehicle", check_type: "document_expiry").find_each do |requirement|
        config = requirement.auto_check_config || {}
        next unless config["document_model"] == "VehicleDocument"

        document_type = config["document_type"]
        Vehicle.find_each do |vehicle|
          ComplianceGateService.evaluate_requirement(nil, requirement, vehicle)
        rescue StandardError
          next
        end
      end
    end

    def check_driver_documents
      ComplianceRequirement.active.where(applies_to: "driver", check_type: "document_expiry").find_each do |requirement|
        config = requirement.auto_check_config || {}
        next unless config["document_model"] == "DriverDocument"

        User.where(role: :driver).find_each do |driver|
          ComplianceGateService.evaluate_requirement(nil, requirement, driver)
        rescue StandardError
          next
        end
      end
    end
  end
end
