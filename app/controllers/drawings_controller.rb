class DrawingsController < ApplicationController
  before_action :require_admin
  before_action :set_drawing, except: %i[index]

  def index
    drawings = Drawing.all.order(id: :desc)
    @drawings = set_pagination_for(drawings, 30)
  end

  def show; end

  def update
    if @drawing.update(drawing_params)
      redirect_to drawing_path(@drawing.aid), notice: "更新しました"
    else
      flash.now[:alert] = "更新できませんでした"
      render :show
    end
  end

  def create_variant
    if @drawing.encode_and_upload
      redirect_to drawing_path(@drawing.aid), notice: "画像を生成しました"
    else
      flash.now[:alert] = "画像を生成できませんでした"
      render :show
    end
  end

  def delete_variant
    if @drawing.delete_variant
      redirect_to drawing_path(@drawing.aid), notice: "variantを削除しました"
    else
      flash.now[:alert] = "variantを削除できませんでした"
      render :show
    end
  end

  private

  def drawing_params
    params.expect(
      drawing: [
        :name,
        :description,
        :visibility,
        :status
      ]
    )
  end

  def set_drawing
    @drawing = Drawing.find_by(aid: params[:aid])
  end
end
