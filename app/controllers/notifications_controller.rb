class NotificationsController < ApplicationController
  def index
    scope = current_user.notifications.active_feed.order(created_at: :desc)
    scope = scope.where(category: params[:category]) if params[:category].present?
    scope = scope.where(priority: params[:priority]) if params[:priority].present?
    scope = scope.where(notification_type: params[:notification_type]) if params[:notification_type].present?
    if params[:read].present?
      read = ActiveModel::Type::Boolean.new.cast(params[:read])
      scope = read ? scope.where.not(read_at: nil) : scope.where(read_at: nil)
    end

    page = params[:page].to_i.positive? ? params[:page].to_i : 1
    per_page = [params[:per_page].to_i.positive? ? params[:per_page].to_i : 25, 100].min
    total = scope.count
    rows = scope.offset((page - 1) * per_page).limit(per_page)

    data = rows.map { |n| payload(n) }
    data = data.group_by { |n| n[:group_key] || "ungrouped" } if ActiveModel::Type::Boolean.new.cast(params[:grouped])

    render json: {
      data: data,
      meta: {
        page: page,
        per_page: per_page,
        total: total,
        unread_count: current_user.notifications.unread.count
      }
    }
  end

  def unread_count
    scope = current_user.notifications.active_feed
    render json: {
      total: scope.unread.count,
      by_category: scope.unread.group(:category).count
    }
  end

  def mark_read
    notification = current_user.notifications.find(params[:id])
    notification.update!(read_at: Time.current)
    render json: payload(notification)
  end

  def mark_all_read
    scope = current_user.notifications.unread
    scope = scope.where(category: params[:category]) if params[:category].present?
    scope.update_all(read_at: Time.current, updated_at: Time.current)
    head :no_content
  end

  def archive
    notification = current_user.notifications.find(params[:id])
    notification.update!(archived_at: Time.current)
    render json: payload(notification)
  end

  def destroy
    notification = current_user.notifications.find(params[:id])
    notification.destroy!
    head :no_content
  end

  private

  def payload(notification)
    {
      id: notification.id,
      notification_type: notification.notification_type,
      category: notification.category,
      title: notification.title,
      body: notification.body,
      priority: notification.priority,
      data: notification.data,
      group_key: notification.group_key,
      action_url: notification.action_url,
      action_type: notification.action_type,
      read_at: notification.read_at,
      seen_at: notification.seen_at,
      archived_at: notification.archived_at,
      delivered_via: notification.delivered_via,
      created_at: notification.created_at
    }
  end
end
