class Chats::InboxesController < ApplicationController
  def index
    threads = scoped_threads.includes(:trip)

    render json: threads.order(last_message_at: :desc, updated_at: :desc).map { |thread| inbox_payload(thread) }
  end

  private

  def scoped_threads
    if current_user.admin? || current_user.supervisor?
      ChatThread.all
    elsif current_user.dispatcher?
      ChatThread.where(dispatcher_id: current_user.id)
    elsif current_user.driver?
      ChatThread.where(driver_id: current_user.id)
    else
      ChatThread.none
    end
  end

  def inbox_payload(thread)
    latest_message = thread.messages.order(created_at: :desc).first
    unread_count = thread.messages.where(read_at: nil).where.not(sender_id: current_user.id).count

    {
      thread_id: thread.id,
      trip_id: thread.trip_id,
      trip_reference_code: thread.trip&.reference_code,
      trip_status: thread.trip&.status,
      last_message_at: thread.last_message_at,
      last_message_preview: latest_message&.body&.truncate(120),
      unread_count: unread_count
    }
  end
end
