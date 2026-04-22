class SessionsController < ApplicationController
  before_action :require_admin, except: %i[ start signout ]
  before_action :require_signin, only: %i[ signout ]
  before_action :require_signout, only: %i[ start ]
  before_action :set_account, except: %i[ start signout ]
  before_action :set_session, only: %i[ show update ]

  def start
  end

  def signout
    if sign_out
      redirect_to root_path, notice: "サインアウトしました"
    else
      redirect_to root_path, alert: "サインアウトできませんでした"
    end
  end

  # 以下サインイン済み #

  def index
    sessions = Session.all.order(id: :desc).where(account: @account)
    @sessions = set_pagination_for(sessions)
  end

  def show
  end

  def update
    if @session.update(session_params)
      redirect_to account_session_path(@account.aid, @session.aid), notice: "更新しました"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_account
    @account = Account.find_by(aid: params.expect(:account_aid))
  end

  def set_session
    @session = Session.find_by(account: @account, aid: params[:aid])
  end

  def session_params
    params.expect(
      session: [
        :name,
        :status
      ]
    )
  end
end
