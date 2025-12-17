module ActivityPub
  class InboxesController < ApplicationController
    include ActivityPub::SignatureVerification

    skip_before_action :verify_authenticity_token

    def create
      body = request.body.read
      payload = JSON.parse(body)

      ActivityPub::ProcessInboxJob.perform_later(payload)

      render json: {}, status: 202
    rescue JSON::ParserError
      render json: { error: 'Invalid JSON' }, status: 400
    end
  end
end
