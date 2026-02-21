require "csv"

class Audit::LogsController < ApplicationController
  def index
    authorize AuditLog, :index?

    scope = filtered_scope(AuditLog.includes(:actor).order(occurred_at: :desc))
    page = pagination_page
    per_page = pagination_per_page(50)

    render json: {
      data: scope.offset((page - 1) * per_page).limit(per_page).map { |log| payload(log) },
      meta: { page: page, per_page: per_page, total: scope.count }
    }
  end

  def resource
    authorize AuditLog, :index?

    resource_type = params[:resource_type].to_s.classify
    resource_id = params[:resource_id]

    scope = AuditLog.where(auditable_type: resource_type, auditable_id: resource_id).or(
      AuditLog.where(associated_type: resource_type, associated_id: resource_id)
    ).order(occurred_at: :asc)

    render json: { data: scope.limit(1000).map { |log| payload(log) } }
  end

  def by_user
    authorize AuditLog, :index?

    scope = AuditLog.where(actor_id: params[:user_id]).order(occurred_at: :desc)
    render json: { data: scope.limit(1000).map { |log| payload(log) } }
  end

  def summary
    authorize AuditLog, :summary?

    now = Time.current
    scope = AuditLog.where(occurred_at: 30.days.ago..now)

    render json: {
      total_entries: AuditLog.count,
      last_24h: AuditLog.where(occurred_at: 24.hours.ago..now).count,
      by_severity: scope.group(:severity).count,
      by_category: scope.group(:category).count,
      top_actors: top_actors(scope),
      recent_critical: AuditLog.where(severity: %w[critical security]).order(occurred_at: :desc).limit(10).map { |log| payload(log) }
    }
  end

  def export
    authorize AuditLog, :export?

    scope = filtered_scope(AuditLog.order(occurred_at: :desc)).limit(10_000)
    csv = CSV.generate(headers: true) do |out|
      out << %w[event_id occurred_at action category severity actor_id actor_role auditable_type auditable_id description request_id]
      scope.find_each do |log|
        out << [log.event_id, log.occurred_at.iso8601, log.action, log.category, log.severity, log.actor_id, log.actor_role, log.auditable_type, log.auditable_id, log.description, log.request_id]
      end
    end

    audit(action: "system.data_exported", auditable: current_user, metadata: { export: "audit_logs", count: scope.count })

    send_data csv, filename: "audit_logs_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv", type: "text/csv"
  end

  private

  def filtered_scope(scope)
    scope = scope.where(category: params[:category]) if params[:category].present?
    requested_action = params[:event_action].presence || (params[:action] if params[:action].present? && params[:action] != action_name)
    scope = scope.where(action: requested_action) if requested_action.present?
    scope = scope.where(severity: params[:severity]) if params[:severity].present?
    scope = scope.where(actor_id: params[:actor_id]) if params[:actor_id].present?
    scope = scope.where(auditable_type: params[:auditable_type].to_s.classify) if params[:auditable_type].present?
    scope = scope.where(auditable_id: params[:auditable_id]) if params[:auditable_id].present?
    scope = scope.where(request_id: params[:request_id]) if params[:request_id].present?

    if params[:from_date].present?
      from = Time.zone.parse(params[:from_date]) rescue nil
      scope = scope.where("occurred_at >= ?", from) if from
    end

    if params[:to_date].present?
      to = Time.zone.parse(params[:to_date]) rescue nil
      scope = scope.where("occurred_at <= ?", to) if to
    end

    if params[:search].present?
      pattern = "%#{params[:search]}%"
      scope = scope.where("description ILIKE ?", pattern)
    end

    scope
  end

  def payload(log)
    {
      id: log.id,
      event_id: log.event_id,
      action: log.action,
      category: log.category,
      severity: log.severity,
      actor: { id: log.actor_id, name: log.actor&.name, role: log.actor_role, type: log.actor_type, ip: log.actor_ip },
      auditable: { type: log.auditable_type, id: log.auditable_id },
      associated: { type: log.associated_type, id: log.associated_id },
      description: log.description,
      changes: log.changeset,
      metadata: log.metadata,
      request_id: log.request_id,
      occurred_at: log.occurred_at,
      created_at: log.created_at
    }
  end

  def pagination_page
    params[:page].to_i.positive? ? params[:page].to_i : 1
  end

  def pagination_per_page(default)
    [params[:per_page].to_i.positive? ? params[:per_page].to_i : default, 100].min
  end

  def top_actors(scope)
    counts = scope.where.not(actor_id: nil).group(:actor_id).order(Arel.sql("COUNT(*) DESC")).limit(10).count
    users = User.where(id: counts.keys).index_by(&:id)
    counts.map do |actor_id, action_count|
      { user_id: actor_id, name: users[actor_id]&.name, action_count: action_count }
    end
  end
end
