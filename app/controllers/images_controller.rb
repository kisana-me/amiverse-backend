class ImagesController < ApplicationController
  before_action :require_signin
  before_action :set_image, only: %i[show]
  before_action :set_correct_image, only: %i[edit update destroy variants_create variants_destroy]

  def index
    images = Image.all
    @images = set_pagination_for(images)
  end

  def show; end

  def new
    @image = Image.new
  end

  def edit; end

  def create
    @image = Image.new(image_params)
    @image.account = @current_account
    if @image.save
      redirect_to images_path, notice: "作成しました"
    else
      flash.now[:alert] = "作成できませんでした"
      render :new
    end
  end

  def update
    if @image.update(image_params)
      redirect_to image_path(@image.aid), notice: "更新しました"
    else
      flash.now[:alert] = "更新できませんでした"
      render :edit
    end
  end

  def destroy
    if @image.update(status: :deleted)
      redirect_to images_path, notice: "削除しました"
    else
      flash.now[:alert] = "削除できませんでした"
      render :edit
    end
  end

  def variants_create
    url = @image.image_url(variant_type: params[:variant_type])
    if url
      redirect_to image_path(@image.aid), notice: "画像を生成しました#{url}"
    else
      flash.now[:alert] = "画像を生成できませんでした"
      render :edit
    end
  end

  def variants_destroy
    if @image.delete_variants
      redirect_to image_path(@image.aid), notice: "variantsを削除しました"
    else
      flash.now[:alert] = "variantsを削除できませんでした"
      render :edit
    end
  end

  private

  def image_params
    params.expect(
      image: %i[
        image
        name
        description
        visibility
      ]
    )
  end

  def set_image
    @image = Image.is_normal.isnt_closed.find_by(aid: params[:aid])
    return if @image

    @image = Image.unscoped.find_by(aid: params[:aid])
    return if admin? && @image

    render_404
  end

  def set_correct_image
    return render_404 unless @current_account

    @image = @current_account.images.is_normal.find_by(aid: params[:aid])
    return if @image

    @image = Image.unscoped.find_by(aid: params[:aid])
    return if admin? && @image

    render_404
  end
end
