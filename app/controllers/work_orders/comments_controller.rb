module WorkOrders
  class CommentsController < ApplicationController
    before_action :set_work_order

    def index
      authorize @work_order, :comments?

      data = @work_order.comments.includes(:user).order(created_at: :asc).map do |comment|
        {
          id: comment.id,
          comment: comment.comment,
          comment_type: comment.comment_type,
          metadata: comment.metadata,
          user: { id: comment.user_id, name: comment.user&.name },
          created_at: comment.created_at
        }
      end

      render json: { data: data }
    end

    def create
      authorize @work_order, :comments?

      comment = @work_order.comments.create!(
        user: current_user,
        comment: params.require(:comment),
        comment_type: "note"
      )

      render json: {
        id: comment.id,
        work_order_id: comment.work_order_id,
        comment: comment.comment,
        comment_type: comment.comment_type,
        metadata: comment.metadata,
        user: { id: current_user.id, name: current_user.name },
        created_at: comment.created_at
      }, status: :created
    end

    private

    def set_work_order
      @work_order = WorkOrder.find(params[:work_order_id])
    end
  end
end
