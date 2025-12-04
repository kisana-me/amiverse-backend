class NotificationsController < ApplicationController
  before_action :require_signin
  before_action :require_admin

  def new
  end

  def create
    content = params[:content]

    if content.present?
      Account.is_normal.find_each do |account|
        NotificationCreator.call(
          actor: nil,
          recipient: account,
          action: :system,
          content: content
        )
      end
      flash[:notice] = "全ユーザーへのシステム通知の配信を完了しました。"
    else
      flash[:alert] = "通知内容を入力してください。"
    end
    
    redirect_to new_notification_path
  end
end
