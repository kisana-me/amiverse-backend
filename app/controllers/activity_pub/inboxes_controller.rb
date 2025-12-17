module ActivityPub
  class InboxesController < ApplicationController
    include ActivityPub::SignatureVerification

    skip_before_action :verify_authenticity_token

    def create
      ActivityPub::ProcessInboxJob.perform_later(request.body.read)
      render json: {}, status: :accepted
    end
  end
end
