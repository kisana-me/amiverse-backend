class CoinTransactionsController < ApplicationController
  before_action :require_admin
  before_action :set_coin_transaction, only: %i[ show update ]

  def show
  end

  def new
    @coin_transaction = CoinTransaction.new
    @account_aid = params[:account_aid]
  end

  def create
    account = Account.find_by(aid: params[:account_aid])
    unless account
      redirect_to new_coin_transaction_path(account_aid: params[:account_aid]), alert: "アカウントが見つかりません"
      return
    end

    kind = params[:kind]
    amount = params[:amount].to_i.abs
    memo = params[:memo].presence

    if amount.zero?
      redirect_to new_coin_transaction_path(account_aid: account.aid), alert: "金額は0以外を指定してください"
      return
    end

    transaction =
      if CoinTransaction::DEBIT_KINDS.include?(kind)
        CoinService.spend(account, amount, kind: kind, memo: memo)
      else
        CoinService.grant(account, amount, kind: kind, memo: memo)
      end

    if transaction
      redirect_to coin_account_path(account.aid), notice: "取引を作成しました"
    else
      redirect_to new_coin_transaction_path(account_aid: account.aid), alert: "残高が不足しています"
    end
  end

  def update
    if @coin_transaction.update(memo: params.dig(:coin_transaction, :memo))
      redirect_to coin_transaction_path(@coin_transaction.aid), notice: "メモを更新しました"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_coin_transaction
    @coin_transaction = CoinTransaction.find_by(aid: params.expect(:aid))
  end
end
