class V1::DrawingsController < V1::ApplicationController
  # POST /v1/drawings/create
  def create
    drawing = Drawing.new(drawing_params)

    if drawing.save
      random_drawing = Drawing
        .is_normal
        .where.not(id: drawing.id)
        .left_outer_joins(:posts)
        .where("drawings.account_id IS NULL OR posts.status = ?", Post.statuses[:normal])
        .distinct
        .order(Arel.sql("RAND()"))
        .first || drawing

      render json: {
        status: "success",
        message: "保存しました",
        data: {
          drawing: drawing_payload(drawing),
          random_drawing: drawing_payload(random_drawing)
        }
      }, status: :ok
    else
      render_error("保存に失敗しました", :unprocessable_entity, drawing.errors.full_messages)
    end
  end

  private

  def drawing_payload(drawing)
    payload = {
      aid: drawing.aid,
      name: drawing.name,
      description: drawing.description,
      image_url: drawing.image_url,
      created_at: drawing.created_at
    }

    if drawing.account.present?
      payload[:account] = {
        aid: drawing.account.aid,
        name: drawing.account.name,
        name_id: drawing.account.name_id,
        icon_url: drawing.account.icon_url
      }
    end

    payload
  end

  def drawing_params
    params.expect(
      drawing: [
        :data,
        :name,
        :description
      ]
    )
  end

  def render_error(message, status, errors = nil)
    payload = { status: "error", message: message }
    payload[:errors] = errors if errors
    render json: payload, status: status
  end
end
