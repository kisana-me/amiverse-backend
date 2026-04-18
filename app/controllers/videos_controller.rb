class VideosController < ApplicationController
  before_action :require_admin
  before_action :set_video, except: %i[index]

  def index
    videos = Video.all.order(id: :desc)
    @videos = set_pagination_for(videos)
  end

  def show; end

  def update
    if @video.update(video_params)
      redirect_to video_path(@video.aid), notice: "更新しました"
    else
      flash.now[:alert] = "更新できませんでした"
      render :show
    end
  end

  def create_variant
    if @video.create_variant(params[:variant_type])
      redirect_to video_path(@video.aid), notice: "動画を生成しました"
    else
      flash.now[:alert] = "動画を生成できませんでした"
      render :show
    end
  end

  def delete_variant
    if @video.delete_variant
      redirect_to video_path(@video.aid), notice: "variantを削除しました"
    else
      flash.now[:alert] = "variantを削除できませんでした"
      render :show
    end
  end

  def delete_original
    if @video.delete_original
      redirect_to video_path(@video.aid), notice: "originalを削除しました"
    else
      flash.now[:alert] = "originalを削除できませんでした"
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
    @video = Video.find_by(aid: params[:aid])
  end
end
