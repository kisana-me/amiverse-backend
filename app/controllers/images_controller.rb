class ImagesController < ApplicationController
  before_action :require_admin
  before_action :set_image, except: %i[index]

  def index
    images = Image.all.order(id: :desc)
    @images = set_pagination_for(images, 30)
  end

  def show; end

  def update
    if @image.update(image_params)
      redirect_to image_path(@image.aid), notice: "更新しました"
    else
      flash.now[:alert] = "更新できませんでした"
      render :show
    end
  end

  def create_variant
    if @image.create_variant(params[:variant_type])
      redirect_to image_path(@image.aid), notice: "画像を生成しました"
    else
      flash.now[:alert] = "画像を生成できませんでした"
      render :show
    end
  end

  def delete_variant
    if @image.delete_variant
      redirect_to image_path(@image.aid), notice: "variantを削除しました"
    else
      flash.now[:alert] = "variantを削除できませんでした"
      render :show
    end
  end

  def delete_original
    if @image.delete_original
      redirect_to image_path(@image.aid), notice: "originalを削除しました"
    else
      flash.now[:alert] = "originalを削除できませんでした"
      render :show
    end
  end

  private

  def image_params
    params.expect(
      image: [
        :name,
        :description,
        :visibility,
        :status
      ]
    )
  end

  def set_image
    @image = Image.find_by(aid: params[:aid])
  end
end
