class V1::EmojisController < V1::ApplicationController
  def groups_index
    groups = Emoji.is_normal.where.not(group: [nil, '']).distinct.pluck(:group)
    render json: { groups: groups }, status: :ok
  end

  def groups_show
    group_name = params[:group_name]
    if group_name.present?
      @emojis = Emoji.is_normal.where(group: group_name)
      render :groups_show, formats: [:json]
    else
      render json: { status: 'error', message: '絵文字のグループが指定されていません' }, status: :bad_request
    end
  end

  def show
    emoji = Emoji.is_normal.find_by(aid: params[:aid])
    if emoji
      render partial: 'v1/emojis/emoji', locals: { emoji: emoji }, formats: [:json]
    else
      render json: { status: 'error', message: '絵文字が見つかりませんでした' }, status: :not_found
    end
  end
end
