class AccountsController < ApplicationController
  before_action :require_admin

  def show
    username, domain = NormalizeNameIdService.call(params[:name_id])

    if domain.nil?
      # ローカルユーザー
      @account = Account.find_by(name_id: username)
    else
      # リモートユーザー
      @account = ActivityPub::Resolve::Actor.by_username_domain(username, domain)
    end

    if @account.nil?
      render plain: "Account not found: #{params[:name_id]}", status: 404
    end
  end
end
