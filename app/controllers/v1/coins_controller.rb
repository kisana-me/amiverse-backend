class V1::CoinsController < V1::ApplicationController
  before_action :require_signin

  def show
    render json: { status: "success", coin_balance: @current_account.coin_balance }
  end

  def history
    cursor_time = params[:cursor].present? ? Time.at(params[:cursor].to_f) : Time.current

    @transactions = @current_account.coin_transactions
                                    .recent
                                    .where("created_at < ?", cursor_time)
                                    .limit(20)

    if @transactions.present?
      response.headers["X-Next-Cursor"] = @transactions.last.created_at.to_f.to_s
    end

    render template: "v1/coins/history", formats: [ :json ]
  end
end
