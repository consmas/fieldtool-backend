class Api::V1::Client::BaseController < ActionController::API
  include Pundit::Authorization

  before_action :authenticate_client_user!

  rescue_from ActiveRecord::RecordNotFound do |error|
    render json: { error: error.message }, status: :not_found
  end

  private

  attr_reader :current_client_user, :current_client

  def authenticate_client_user!
    token = request.headers["Authorization"].to_s.remove("Bearer ").strip
    payload = ClientAuth::JwtService.decode(token)
    return render json: { error: "Unauthorized" }, status: :unauthorized if payload.blank? || payload[:type] != "client"

    @current_client_user = ClientUser.find_by(id: payload[:sub], client_id: payload[:client_id], is_active: true)
    return render json: { error: "Unauthorized" }, status: :unauthorized if @current_client_user.nil?

    @current_client = @current_client_user.client
  end
end
