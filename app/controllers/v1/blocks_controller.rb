class V1::BlocksController < V1::ApplicationController
  before_action :require_signin
  before_action :set_account

  # POST /v1/blocks
  def index
    blocks = @current_account.active_blockings.includes(:blocked).map do |block|
      {
        account_aid: block.blocked.aid,
        account_name: block.blocked.name,
        account_name_id: block.blocked.name_id
      }
    end

    render json: blocks, status: :ok
  end

  # POST /v1/accounts/:account_aid/block
  def create
    return render_error('自分自身をブロックすることはできません', :unprocessable_entity) if @account == @current_account

    block = @current_account.active_blockings.find_or_initialize_by(blocked: @account)

    if block.save
      render json: {
        status: 'success',
        message: 'ブロックしました',
        data: { account_aid: @account.aid }
      }, status: :ok
    else
      render_error('ブロックの保存に失敗しました', :unprocessable_entity, block.errors.full_messages)
    end
  end

  # DELETE /v1/accounts/:account_aid/block
  def destroy
    block = @current_account.active_blockings.find_by(blocked: @account)
    return render_error('ブロックしていません', :not_found) unless block

    if block.destroy
      render json: { status: 'success', message: 'ブロックを解除しました' }, status: :ok
    else
      render_error('ブロック解除に失敗しました', :unprocessable_entity, block.errors.full_messages)
    end
  end

  private

  def set_account
    @account = Account.is_normal.find_by(aid: params[:account_aid])
    render_error('アカウントが見つかりません', :not_found) unless @account
  end

  def render_error(message, status, errors = nil)
    payload = { status: 'error', message: message }
    payload[:errors] = errors if errors
    render json: payload, status: status
  end
end
