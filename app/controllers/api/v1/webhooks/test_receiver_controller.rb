class Api::V1::Webhooks::TestReceiverController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    return head :not_found if Rails.env.production?

    Rails.logger.info(
      "[WebhookTestReceiver] headers=#{request.headers.env.select { |k, _| k.start_with?('HTTP_X_CONSMAS') || k == 'HTTP_USER_AGENT' }} payload=#{request.raw_post}"
    )

    render json: { ok: true }
  end
end
