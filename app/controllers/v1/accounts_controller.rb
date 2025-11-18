class V1::AccountsController < V1::ApplicationController
  def index
    @accounts = Account.all
    render template: 'v1/accounts/index', formats: [:json]
  end

  def show
    @account = Account.find_by(aid: params[:aid])
    if @account
      render template: 'v1/accounts/show', formats: [:json]
    else
      render json: { error: 'Account not found' }, status: :not_found
    end
  end

  def create
    @account = Account.new(account_params)
    if @account.save
      render template: 'v1/accounts/show', formats: [:json], status: :created
    else
      render json: { errors: @account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @account = Account.find_by(aid: params[:aid])
    @account.update(account_params)
    if @account.save
      render template: 'v1/accounts/show', formats: [:json]
    else
      render json: { errors: @account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @account = Account.find_by(aid: params[:aid])
    if @account.update(visibility: :deleted)
      render json: { status: 'success' }
    else
      render json: { errors: @account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.expect(
      account: [
        :name,
        :name_id,
        :email,
        :password,
        :password_confirmation
      ]
    )
  end
end
