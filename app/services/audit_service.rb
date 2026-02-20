class AuditService
  def self.record(action:, auditable:, actor: nil, associated: nil, changes: nil, metadata: {}, description: nil, severity: nil, request_context: nil)
    registry = AuditActionRegistry.fetch(action)
    raise ArgumentError, "Unknown audit action: #{action}" unless registry

    raw_changes = changes || extract_changes(auditable)
    enriched_changes = enrich_changes(raw_changes, auditable)
    final_description = description || build_description(action, auditable, enriched_changes, registry)

    AuditLogWriteJob.perform_later(
      event_id: SecureRandom.uuid,
      action: action,
      category: registry[:category],
      severity: severity || registry[:severity],
      actor_id: actor&.id,
      actor_type: determine_actor_type(actor),
      actor_role: actor&.role,
      actor_ip: request_context&.dig(:ip),
      actor_user_agent: request_context&.dig(:user_agent),
      auditable_type: auditable.class.name,
      auditable_id: auditable.id,
      associated_type: associated&.class&.name,
      associated_id: associated&.id,
      description: final_description,
      changeset: enriched_changes || {},
      metadata: metadata || {},
      request_id: request_context&.dig(:request_id),
      session_id: request_context&.dig(:session_id),
      occurred_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error("AUDIT_RECORD_FAILED #{action}: #{e.message}")
  end

  def self.record_status_change(auditable:, actor:, from:, to:, **opts)
    record(
      action: "#{auditable.class.name.underscore}.status_changed",
      auditable: auditable,
      actor: actor,
      changes: { status: { from: from, to: to } },
      **opts
    )
  end

  class << self
    private

    def extract_changes(record)
      return nil unless record.respond_to?(:previous_changes)

      meaningful = record.previous_changes.except("created_at", "updated_at", "lock_version")
      return nil if meaningful.blank?

      meaningful.transform_values { |vals| { from: vals[0], to: vals[1] } }
    end

    def enrich_changes(changes, auditable)
      return nil unless changes.is_a?(Hash)

      changes.each_with_object({}) do |(field, values), out|
        out[field] = values.deep_dup
        next unless field.to_s.end_with?("_id")
        next if values[:from].blank? && values[:to].blank?

        assoc_name = field.to_s.delete_suffix("_id")
        reflection = auditable.class.reflect_on_association(assoc_name.to_sym)
        next if reflection.nil?

        klass = reflection.klass
        if values[:from].present?
          from_obj = klass.find_by(id: values[:from])
          out[field][:from_display] = from_obj&.try(:name) || from_obj&.try(:number) || from_obj&.try(:title)
        end

        if values[:to].present?
          to_obj = klass.find_by(id: values[:to])
          out[field][:to_display] = to_obj&.try(:name) || to_obj&.try(:number) || to_obj&.try(:title)
        end
      end
    end

    def build_description(_action, auditable, changes, registry)
      reference = auditable_reference(auditable)
      if changes.is_a?(Hash) && changes.key?(:status)
        "#{registry[:description]}: #{reference} from '#{changes[:status][:from]}' to '#{changes[:status][:to]}'"
      else
        "#{registry[:description]}: #{reference}"
      end
    end

    def auditable_reference(record)
      case record.class.name
      when "Trip" then "Trip ##{record.try(:reference_code) || record.id}"
      when "ExpenseEntry" then "Expense ##{record.id}"
      when "Vehicle" then "Vehicle #{record.try(:license_plate) || record.id}"
      when "WorkOrder" then "WO #{record.try(:work_order_number) || record.id}"
      when "Incident" then "Incident ##{record.try(:incident_number) || record.id}"
      else "#{record.class.name} ##{record.id}"
      end
    end

    def determine_actor_type(actor)
      actor.present? ? "user" : "system"
    end
  end
end
