module Maintenance
  class EtaBatchRecalculationJob < ApplicationJob
    queue_as :low

    def perform
      Trip.where(status: :en_route).find_each do |trip|
        Trips::EtaRecalculationJob.perform_later(trip.id)
      end
    end
  end
end
