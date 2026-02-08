class Trips::AttachmentsController < ApplicationController
  include Rails.application.routes.url_helpers

  def update
    trip = Trip.find(params[:trip_id])
    authorize trip

    attachments = attachments_params

    trip.client_rep_signature.attach(attachments[:client_rep_signature]) if attachments[:client_rep_signature].present?
    trip.proof_of_fuelling.attach(attachments[:proof_of_fuelling]) if attachments[:proof_of_fuelling].present?
    trip.inspector_signature.attach(attachments[:inspector_signature]) if attachments[:inspector_signature].present?
    trip.security_signature.attach(attachments[:security_signature]) if attachments[:security_signature].present?
    trip.driver_signature.attach(attachments[:driver_signature]) if attachments[:driver_signature].present?

    trip.save!

    render json: {
      trip_id: trip.id,
      client_rep_signature_attached: trip.client_rep_signature.attached?,
      proof_of_fuelling_attached: trip.proof_of_fuelling.attached?,
      inspector_signature_attached: trip.inspector_signature.attached?,
      security_signature_attached: trip.security_signature.attached?,
      driver_signature_attached: trip.driver_signature.attached?,
      client_rep_signature_url: attachment_url(trip.client_rep_signature),
      proof_of_fuelling_url: attachment_url(trip.proof_of_fuelling),
      inspector_signature_url: attachment_url(trip.inspector_signature),
      security_signature_url: attachment_url(trip.security_signature),
      driver_signature_url: attachment_url(trip.driver_signature)
    }
  end

  private

  def attachments_params
    params.require(:attachments).permit(
      :client_rep_signature,
      :proof_of_fuelling,
      :inspector_signature,
      :security_signature,
      :driver_signature
    )
  end

  def attachment_url(attachment)
    return nil unless attachment&.attached?

    Rails.application.routes.url_helpers.rails_blob_url(
      attachment,
      host: request.base_url,
      only_path: false
    )
  end
end
