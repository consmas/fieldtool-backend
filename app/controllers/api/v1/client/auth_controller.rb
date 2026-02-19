class Api::V1::Client::AuthController < ActionController::API
  def login
    user = ClientUser.find_by(email: params[:email].to_s.downcase)
    return render json: { error: "Invalid credentials" }, status: :unauthorized if user.nil? || !user.is_active?
    return render json: { error: "Invalid credentials" }, status: :unauthorized unless user.authenticate(params[:password].to_s)

    user.update!(last_login_at: Time.current)
    token = ClientAuth::JwtService.encode(user)

    render json: {
      token: token,
      token_type: "Bearer",
      client_user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        client_id: user.client_id
      }
    }
  end

  def logout
    head :no_content
  end

  def forgot_password
    render json: { message: "Password reset flow not yet enabled" }, status: :not_implemented
  end

  def reset_password
    render json: { message: "Password reset flow not yet enabled" }, status: :not_implemented
  end
end
