class AccountsController < ApplicationController
  before_action :require_admin
  before_action :set_account, only: %i[ show update ]

  def index
    accounts = Account.all.order(id: :desc).includes(:icon)
    @accounts = set_pagination_for(accounts)
  end

  def heatmap
    @account = Account.find_by(aid: params[:aid])
    if @account
      data = @account.post_heatmap
      @days = data[:days]
      @max = data[:max]
    end
  end

  def coin
    @account = Account.find_by(aid: params[:aid])
    if @account
      per = 100
      @page = [ params[:page].to_i, 1 ].max
      @transactions = @account.coin_transactions.recent.offset((@page - 1) * per).limit(per)
      @has_more = @page * per < @account.coin_transactions.count
    end
  end

  def show
  end

  def update
    if @account.update(account_params)
      redirect_to account_path(@account.aid), notice: "更新しました"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_account
    @account = Account.find_by(aid: params.expect(:aid))
  end

  def account_params
    params.expect(
      account: [
        :status
      ]
    )
  end
end
