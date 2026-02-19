class DevicesController < ApplicationController
  def create
    token = params.require(:token)
    platform = params.require(:platform)

    DeviceToken.transaction do
      current_user.device_tokens.where(platform: platform).where.not(token: token).update_all(is_active: false, updated_at: Time.current)
      device = DeviceToken.find_or_initialize_by(token: token)
      device.assign_attributes(
        user_id: current_user.id,
        platform: platform,
        device_name: params[:device_name],
        is_active: true,
        last_used_at: Time.current
      )
      device.save!
      render json: { id: device.id, token: device.token, platform: device.platform, is_active: device.is_active }, status: :created
    end
  end

  def destroy
    device = current_user.device_tokens.find_by!(token: params[:token])
    device.update!(is_active: false)
    head :no_content
  end
end
