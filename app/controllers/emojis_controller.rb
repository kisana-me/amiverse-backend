class EmojisController < ApplicationController
  before_action :require_signin, except: %i[ index show ]
  before_action :set_emoji, only: %i[ show ]
  # before_action :set_correct_post, only: %i[ edit update destroy ]

  def index
    @emojis = Emoji.all
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
      redirect_to emoji_path(@emoji.aid), notice: 'Emoji was successfully created.'
    else
      flash.now[:alert] = 'Failed to create the emoji.'
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @emoji.update(emoji_params)
      redirect_to emoji_path(@emoji.aid), notice: 'Emoji was successfully updated.', status: :see_other
    else
      flash.now[:alert] = 'Failed to update the emoji.'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @emoji.update(status: :deleted)
      redirect_to emoji_path(@emoji.aid), notice: 'Emoji was successfully deleted.', status: :see_other
    else
      flash.now[:alert] = 'Failed to delete the emoji.'
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
end
