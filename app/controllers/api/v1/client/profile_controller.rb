class Api::V1::Client::ProfileController < Api::V1::Client::BaseController
  def show
    render json: {
      client: {
        id: current_client.id,
        name: current_client.name,
        code: current_client.code,
        contact_name: current_client.contact_name,
        contact_email: current_client.contact_email,
        contact_phone: current_client.contact_phone,
        billing_email: current_client.billing_email,
        address: current_client.address,
        city: current_client.city,
        region: current_client.region,
        outstanding_balance: current_client.outstanding_balance
      },
      user: {
        id: current_client_user.id,
        name: current_client_user.name,
        email: current_client_user.email,
        phone: current_client_user.phone,
        role: current_client_user.role,
        notification_prefs: current_client_user.notification_prefs
      }
    }
  end

  def update
    current_client_user.update!(notification_prefs: params.require(:notification_prefs).to_unsafe_h)
    render json: { notification_prefs: current_client_user.notification_prefs }
  end

  def password
    current_password = params.require(:current_password)
    new_password = params.require(:new_password)

    return render json: { error: "Current password is invalid" }, status: :unprocessable_entity unless current_client_user.authenticate(current_password)

    current_client_user.update!(password: new_password, password_confirmation: params[:new_password_confirmation] || new_password)
    head :no_content
  end
end
