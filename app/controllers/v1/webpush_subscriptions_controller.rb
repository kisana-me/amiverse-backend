class V1::WebpushSubscriptionsController < V1::ApplicationController
  before_action :require_signin

  def create
    subscription = @current_account.webpush_subscriptions.find_or_initialize_by(endpoint: params[:endpoint])
    subscription.update!(
      p256dh: params[:keys][:p256dh],
      auth_key: params[:keys][:auth]
    )
    head :ok
  end
end
