module ImageProcessable
  # ImageProcessable Ver. 1.0.0

  def process_image(image:, variant_type:)
    resize, extent = set_image_size(variant_type)
    processor = ImageProcessing::MiniMagick
      .source(image.path)
      .gravity('center')
      .strip
      .colorspace("sRGB")
      .coalesce
      .resize(resize)

    if extent.present?
      processor = processor.extent(extent)
    end

    processor
      .quality(80)
      .convert("webp")
      .call
  end

  def validate_image(
    column_name: 'image',
    required: true,
    max_size_mb: 30,
    max_dim: 4096
  )
    file = send(column_name)
    return errors.add(column_name.to_sym, :image_blank) if required && !file

    begin
      image = MiniMagick::Image.read(file)

      # 拡張子チェック
      allowed_content_types = %w[PNG JPEG GIF WEBP]
      errors.add(column_name.to_sym, :image_invalid_format) unless allowed_content_types.include?(image.type)

      # 容量チェック
      size_in_mb = (file.size.to_f / 1024 / 1024).round(2)
      errors.add(column_name.to_sym, :image_too_large, max_size_mb: max_size_mb) if size_in_mb > max_size_mb

      # 解像度チェック
      if image.width > max_dim || image.height > max_dim
        errors.add(column_name.to_sym, :image_dimensions_exceeded, max_dim: max_dim)
      end
    rescue MiniMagick::Invalid
      errors.add(column_name.to_sym, :image_invalid)
    end
  end

  private

  def set_image_size(variant_type)
    resize = '2048x2048>'
    extent = '' # 切り取る
    case variant_type
    # bealive capture
    when 'bealive_capture'
      resize = '600x800^'
      extent = '600x800'
    # icon
    when 'icon'
      resize = '400x400^'
      extent = '400x400'
    when 'q-icon'
      resize = '100x100^'
      extent = '100x100'
    # banner
    when 'banner'
      resize = '1600x1600^'
      extent = '1600x1600'
    when 'q-banner'
      resize = '400x400^'
      extent = '400x400'
    # normal
    when 'normal'
      resize = '2048x2048>'
    when 'q-normal'
      resize = '512x512>'
    when 'd-normal'
      resize = '4096x4096>'
    # emoji
    when 'emoji'
      resize = '200x200>'
    when 'q-emoji'
      resize = '50x50>'
    else
      raise 'Unknown variant_type'
    end
    return resize, extent
  end
end
