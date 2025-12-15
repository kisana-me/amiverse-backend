class VideosController < ApplicationController
  before_action :require_signin
  before_action :require_admin
  before_action :set_video, only: %i[show]
  before_action :set_correct_video, only: %i[edit update destroy create_variant delete_variant delete_original]

  def index
    videos = Video.all.order(id: :desc)
    @videos = set_pagination_for(videos)
  end

  def show; end

  def new
    @video = Video.new
  end

  def edit; end

  def create
    @video = Video.new(video_params)
    @video.account = @current_account
    if @video.save
      redirect_to videos_path, notice: '作成しました'
    else
      flash.now[:alert] = '作成できませんでした'
      render :new
    end
  end

  def update
    if @video.update(video_params)
      redirect_to video_path(@video.aid), notice: '更新しました'
    else
      flash.now[:alert] = '更新できませんでした'
      render :edit
    end
  end

  def destroy
    if @video.update(status: :deleted)
      redirect_to videos_path, notice: '削除しました'
    else
      flash.now[:alert] = '削除できませんでした'
      render :edit
    end
  end

  def create_variant
    if @video.create_variant(params[:variant_type])
      redirect_to video_path(@video.aid), notice: '動画を生成しました'
    else
      flash.now[:alert] = '動画を生成できませんでした'
      render :show
    end
  end

  def delete_variant
    if @video.delete_variant
      redirect_to video_path(@video.aid), notice: 'variantを削除しました'
    else
      flash.now[:alert] = 'variantを削除できませんでした'
      render :show
    end
  end

  def delete_original
    if @video.delete_original
      redirect_to video_path(@video.aid), notice: 'originalを削除しました'
    else
      flash.now[:alert] = 'originalを削除できませんでした'
      render :show
    end
  end

  private

  def video_params
    params.expect(
      video: [
        :name,
        :description,
        :visibility,
        :status
      ]
    )
  end

  def set_video
    @video = Video.is_normal.isnt_closed.find_by(aid: params[:aid])
    return if @video

    @video = Video.unscoped.find_by(aid: params[:aid])
    return if admin? && @video

    render_404
  end

  def set_correct_video
    return render_404 unless @current_account

    @video = @current_account.videos.is_normal.find_by(aid: params[:aid])
    return if @video

    @video = Video.unscoped.find_by(aid: params[:aid])
    return if admin? && @video
    render_404
  end
end
