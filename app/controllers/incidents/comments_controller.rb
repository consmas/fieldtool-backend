class Incidents::CommentsController < ApplicationController
  before_action :set_incident

  def index
    authorize @incident, :show?

    render json: {
      data: @incident.comments.order(created_at: :asc).map do |comment|
        {
          id: comment.id,
          comment: comment.comment,
          comment_type: comment.comment_type,
          metadata: comment.metadata,
          user: { id: comment.user_id, name: comment.user&.name },
          created_at: comment.created_at
        }
      end
    }
  end

  def create
    authorize @incident, :update?

    comment = @incident.comments.create!(
      user: current_user,
      comment: params.require(:comment),
      comment_type: params[:comment_type].presence || "note",
      metadata: params[:metadata] || {}
    )

    audit(action: "incident.updated", auditable: @incident, associated: comment, metadata: { added: "comment" })

    render json: {
      id: comment.id,
      comment: comment.comment,
      comment_type: comment.comment_type,
      metadata: comment.metadata,
      created_at: comment.created_at
    }, status: :created
  end

  private

  def set_incident
    @incident = Incident.find(params[:incident_id])
  end
end
