class SessionsController < ApplicationController
  before_action :require_signin, except: %i[ start ]
  before_action :require_signout, only: %i[ start ]
  before_action :set_session, only: %i[ show edit update destroy ]
  before_action :require_admin, except: %i[ start signout ]

  def start
  end

  def signout
    if sign_out
      redirect_to root_path, notice: 'サインアウトしました'
    else
      redirect_to root_path, alert: 'サインアウトできませんでした'
    end
  end

  # 以下サインイン済み #

  def index
    @sessions = Session.where(account: @current_account)
  end

  def show
  end

  def edit
  end

  def update
    if @session.update!(session_params)
      redirect_to session_path(@session.token_lookup), notice: 'セッションを更新しました'
    else
      render :edit
    end
  end

  def destroy# bad
    @session.update(deleted: true)
    redirect_to sessions_path, notice: 'セッションを削除しました'
  end

  private

  def set_session
    @session = Session.find_by(account: @current_account, lookup: params[:id], deleted: false)
  end

  def session_params
    params.require(:session).permit(:name)
  end
end
