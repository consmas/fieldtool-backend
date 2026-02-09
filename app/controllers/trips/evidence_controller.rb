class Trips::EvidenceController < ApplicationController
  include Rails.application.routes.url_helpers
  def create
    trip = Trip.find(params[:trip_id])
    photo = evidence_params[:photo]
    evidence = trip.evidence.new(evidence_params.except(:photo))
    evidence.uploaded_by = current_user
    evidence.recorded_at ||= Time.current

    authorize evidence

    evidence.photo.attach(photo) if photo.present?

    evidence.save!

    TripEvent.create!(
      trip: trip,
      event_type: "evidence_added",
      message: "Evidence added (#{evidence.kind})",
      created_by: current_user,
      data: {
        kind: evidence.kind,
        recorded_at: evidence.recorded_at,
        note: evidence.note,
        lat: evidence.lat,
        lng: evidence.lng
      }
    )

    render json: evidence_payload(evidence), status: :created
  end

  private

  def evidence_params
    params.require(:evidence).permit(:kind, :note, :lat, :lng, :recorded_at, :photo)
  end

  def evidence_payload(evidence)
    {
      id: evidence.id,
      trip_id: evidence.trip_id,
      kind: evidence.kind,
      note: evidence.note,
      lat: evidence.lat,
      lng: evidence.lng,
      recorded_at: evidence.recorded_at,
      uploaded_by_id: evidence.uploaded_by_id,
      photo_attached: evidence.photo.attached?,
      photo_url: attachment_url(evidence.photo)
    }
  end

  def attachment_url(attachment)
    return nil unless attachment&.attached?

    base_url = ENV["PUBLIC_BASE_URL"].presence || request.base_url

    Rails.application.routes.url_helpers.rails_blob_url(
      attachment,
      host: base_url,
      only_path: false
    )
  end
end
