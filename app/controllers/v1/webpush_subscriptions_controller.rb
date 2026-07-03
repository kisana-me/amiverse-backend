class V1::WebpushSubscriptionsController < V1::ApplicationController
  before_action :require_signin

  def create
    subscription = @current_account.webpush_subscriptions.find_or_initialize_by(endpoint: params[:endpoint])
    subscription.assign_attributes(
      p256dh: params[:keys][:p256dh],
      auth_key: params[:keys][:auth],
      name: WebpushSubscription.device_name_for(request.user_agent),
      status: :normal
    )
    subscription.meta["user_agent"] = request.user_agent.to_s
    subscription.save!
    head :ok
  end

  def index
    subscriptions = @current_account.webpush_subscriptions.is_normal.order(updated_at: :desc)
    current_endpoint = params[:endpoint].to_s

    render json: {
      status: "success",
      data: subscriptions.map do |subscription|
        {
          id: subscription.id,
          name: subscription.name,
          current: current_endpoint.present? && subscription.endpoint == current_endpoint,
          created_at: subscription.created_at,
          updated_at: subscription.updated_at
        }
      end
    }
  end

  def destroy
    subscription = @current_account.webpush_subscriptions.is_normal.find_by(id: params[:id])
    unless subscription
      return render json: { status: "error", message: "登録が見つかりませんでした" }, status: :not_found
    end

    subscription.deleted!
    render json: { status: "success" }
  end
end
