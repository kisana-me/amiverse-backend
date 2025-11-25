class TrendsController < ApplicationController
  before_action :require_signin
  before_action :require_admin

  def index
    @trends = TrendService.current_trends
    @last_updated_at = TrendService.last_updated_at
  end

  def create
    TrendService.update_trends
    redirect_to trends_path, notice: 'Trends updated successfully'
  end
end
