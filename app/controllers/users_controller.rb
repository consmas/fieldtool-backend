class UsersController < ApplicationController
  def index
    authorize User
    users = policy_scope(User)
    render json: users.map { |user| user_payload(user) }
  end

  def show
    user = User.find(params[:id])
    authorize user
    render json: user_payload(user)
  end

  def create
    user = User.new(user_params)
    authorize user
    user.save!
    render json: user_payload(user), status: :created
  end

  def update
    user = User.find(params[:id])
    authorize user
    user.update!(user_params)
    render json: user_payload(user)
  end

  def destroy
    user = User.find(params[:id])
    authorize user
    user.destroy!
    head :no_content
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name, :role)
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
