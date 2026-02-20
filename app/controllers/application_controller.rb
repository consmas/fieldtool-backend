class ApplicationController < ActionController::API
  include AuditContext
  include Pundit::Authorization

  before_action :authenticate_user!
  skip_before_action :authenticate_user!, if: -> { request.path == "/up" }
  before_action :ensure_json_request

  rescue_from ActiveRecord::RecordNotFound do |error|
    render json: { error: error.message }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |error|
    render json: { error: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  rescue_from ActionController::ParameterMissing do |error|
    render json: { error: error.message }, status: :bad_request
  end

  rescue_from Pundit::NotAuthorizedError do
    render json: { error: "Not authorized" }, status: :forbidden
  end

  private

  def ensure_json_request
    return if request.format.json?
    return unless request.headers["Accept"]&.include?("json") || request.headers["Content-Type"]&.include?("json")

    request.format = :json
  end
end
