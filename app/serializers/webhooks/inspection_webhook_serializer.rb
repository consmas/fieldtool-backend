module Webhooks
  class InspectionWebhookSerializer
    def initialize(inspection)
      @inspection = inspection
    end

    def as_json(*)
      {
        id: @inspection.id,
        trip_id: @inspection.trip_id,
        captured_by_id: @inspection.captured_by_id,
        accepted: @inspection.accepted,
        accepted_at: @inspection.accepted_at,
        inspection_verification_status: @inspection.inspection_verification_status,
        load_status: @inspection.load_status,
        core_checklist: @inspection.core_checklist
      }
    end
  end
end
