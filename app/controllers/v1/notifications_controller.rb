class V1::NotificationsController < V1::ApplicationController
  before_action :require_signin

  def index
    cursor_time = params[:cursor].present? ? Time.at(params[:cursor].to_f) : Time.current

    @notifications = @current_account.notifications
                                     .is_normal
                                     .recent
                                     .with_details
                                     .where('created_at < ?', cursor_time)
                                     .limit(20)

    if @notifications.present?
      response.headers['X-Next-Cursor'] = @notifications.last.created_at.to_f.to_s
    end

    # 取得した通知のうち、未読のものを既読にする
    unread_ids = @notifications.select { |n| !n.checked }.map(&:id)
    if unread_ids.any?
      Notification.where(id: unread_ids).update_all(checked: true)
    end
    render template: 'v1/notifications/index', formats: [:json]
  end

  def unread_count
    count = @current_account.notifications.is_normal.unread.count
    render json: { status: 'success', count: count }
  end
end
