class V1::PagesController < V1::ApplicationController
  def index
    render json: { status: "success", message: "Welcome to API v1" }
  end

  def start
    grant_login_bonus if record_daily_visit
    render template: "v1/pages/start", formats: [ :json ]
  end

  private

  def record_daily_visit
    return false unless @current_account

    DailyVisit.create!(account_id: @current_account.id, visited_on: Date.current)
    true
  rescue ActiveRecord::RecordNotUnique
    false
  end

  def grant_login_bonus
    CoinService.grant(@current_account, CoinService::LOGIN_BONUS_AMOUNT, kind: :login_bonus)
  rescue => e
    Rails.logger.error("[login_bonus] #{e.class}: #{e.message}")
  end
end
