class OgImagesController < ApplicationController
  include Base64Images

  def post
    # render template: 'og_images/post', formats: [:svg]

    @post = Post.from_normal_account.is_normal.find_by(aid: params[:aid])
    return render_404 if @post.nil?

    icon_image = @post.account.icon
    @account_icon_base64 = if icon_image.present? && icon_image.normal?
      image_to_base64("/images/variants/#{icon_image.aid}.webp")
    else
      init_icon()
    end

    drawing = @post.drawings.first
    @post_drawing_base64 = if drawing.present? && drawing.normal?
      image_to_base64("/drawings/#{drawing.aid}.png", "png")
    else
      nil
    end

    svg_string = render_to_string(template: "og_images/post", formats: [ :svg ])

    image = Vips::Image.new_from_buffer(svg_string, "")
    png_data = image.write_to_buffer(".png")

    send_data png_data, type: "image/png", disposition: "inline"
  end

  def account
  end

  private

  def image_to_base64(s3_key, image_format = "webp")
    target = StringIO.new

    Image.s3_download(key: s3_key, response_target: target)
    target.rewind
    data = target.read

    base64 = Base64.strict_encode64(data)
    "data:image/#{image_format};base64,#{base64}"
  rescue
    nil
  end
end
