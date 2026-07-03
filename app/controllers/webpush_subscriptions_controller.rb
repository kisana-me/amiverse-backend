class WebpushSubscriptionsController < ApplicationController
  before_action :require_admin
  before_action :set_account
  before_action :set_webpush_subscription, only: %i[ show update ]

  def index
    subscriptions = WebpushSubscription.all.order(id: :desc).where(account: @account)
    @webpush_subscriptions = set_pagination_for(subscriptions)
  end

  def show
  end

  def update
    if @webpush_subscription.update(webpush_subscription_params)
      redirect_to account_webpush_subscription_path(@account.aid, @webpush_subscription.id), notice: "更新しました"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_account
    @account = Account.find_by(aid: params.expect(:account_aid))
  end

  def set_webpush_subscription
    @webpush_subscription = WebpushSubscription.find_by(account: @account, id: params[:id])
  end

  def webpush_subscription_params
    params.expect(
      webpush_subscription: [
        :name,
        :status
      ]
    )
  end
end
