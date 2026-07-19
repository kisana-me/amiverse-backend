class V1::PagesController < V1::ApplicationController
  def index
    render json: { status: "success", message: "Welcome to API v1" }
  end

  def start
    record_daily_visit
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
end
