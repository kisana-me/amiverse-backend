class AccountsController < ApplicationController
  before_action :require_admin
  before_action :set_account, only: %i[ show update ]

  def index
    accounts = Account.includes(:icon)
    @accounts = set_pagination_for(accounts)
  end

  def show
  end

  def update
    if @account.update(account_params)
      redirect_to account_path(@account.aid), notice: '更新しました'
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
        :status,
      ]
    )
  end
end
