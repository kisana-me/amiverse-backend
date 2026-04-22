class EmojisController < ApplicationController
  before_action :require_admin
  before_action :set_emoji, only: %i[ show ]
  before_action :set_group, only: %i[ group ]

  def index
    pairs = Emoji
      .where.not(group: [ nil, "" ])
      .distinct
      .order(:group, :subgroup)
      .pluck(:group, :subgroup)

    @group_subgroups = pairs.group_by(&:first).transform_values do |rows|
      rows.map(&:last).reject(&:blank?)
    end
  end

  def picker
    @groups = Emoji.where.not(group: [ nil, "" ]).distinct.pluck(:group)

    if params[:group].present?
      @emojis = Emoji.where(group: params[:group])
    end

    @mode = params[:mode]
    @target_id = params[:target_id]
  end

  def group
    @emojis = Emoji
      .where(group: @group_name)
      .order(:subgroup, :name_id)

    render_404 if @emojis.blank?
  end

  def show
  end

  def new
    @emoji = Emoji.new
  end

  def edit
  end

  def create
    @emoji = Emoji.new(emoji_params)
    if @emoji.save
      redirect_to emoji_path(@emoji.aid), notice: "Emoji was successfully created."
    else
      flash.now[:alert] = "Failed to create the emoji."
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @emoji.update(emoji_params)
      redirect_to emoji_path(@emoji.aid), notice: "Emoji was successfully updated.", status: :see_other
    else
      flash.now[:alert] = "Failed to update the emoji."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @emoji.update(status: :deleted)
      redirect_to emoji_path(@emoji.aid), notice: "Emoji was successfully deleted.", status: :see_other
    else
      flash.now[:alert] = "Failed to delete the emoji."
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_emoji
    @emoji = Emoji
      .find_by(aid: params.expect(:aid))
    return render_404 unless @emoji

    return if @emoji.normal?

    return if admin?

    render_404
  end

  def emoji_params
    params.expect(
      emoji: [
        :image_aid,
        :name,
        :name_id,
        :description
      ]
    )
  end

  def set_group
    @group_name = params.expect(:group_name)
  end
end
