class Auth::SessionsController < Devise::SessionsController
  respond_to :json

  skip_before_action :authenticate_user!, only: [:create]
  skip_before_action :verify_signed_out_user, only: [:destroy]

  private

  def respond_with(resource, _opts = {})
    render json: { user: user_payload(resource) }, status: :ok
  end

  def respond_to_on_destroy
    render json: { message: "Logged out" }, status: :ok
  end

  def user_payload(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role
    }
  end
end
