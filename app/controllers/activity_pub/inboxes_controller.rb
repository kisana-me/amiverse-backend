module ActivityPub
  class InboxesController < ApplicationController
    include SignatureVerification
    
    # CSRF保護を無効化 (APIとして動作するため)
    skip_before_action :verify_authenticity_token

    def create
      # ここにActivityの処理を記述
      # 通常は非同期ジョブに投げる
      # ActivityPub::ProcessInboxJob.perform_later(request.body.read)

      render json: {}, status: :accepted
    end
  end
end
