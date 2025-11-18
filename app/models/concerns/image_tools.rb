module ImageTools
  # ver 1.0.1
  # images/variants/[variant_type]/[aid].[ext]
  # images/originals/[aid].[ext]
  # original_ext(string)とvariants(json)が必要

  include S3Tools

  def process_image(
    variant_type: 'normal',
    variants_column: 'variants',
    original_ext_column: 'original_ext',
    original_image_path: nil
  )
    return if send(variants_column).include?(variant_type)

    if original_image_path.blank?
      return if send(original_ext_column).blank?

      downloaded_image = Tempfile.new(['downloaded_image'])
      original_image_path = downloaded_image.path
      s3_download(key: "/images/originals/#{aid}.#{send(original_ext_column)}",
                  response_target: original_image_path)
    end
    converted_image = Tempfile.new(['converted_image'])
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
    image = MiniMagick::Image.open(original_image_path)
    if image.frames.many?
      ImageProcessing::MiniMagick
        .source(original_image_path)
        .loader(page: nil)
        .coalesce
        .gravity('center')
        .resize(resize)
        .then do |chain|
        if extent.present?
          chain.extent(extent)
        else
          chain
        end
      end
        .strip
        .auto_orient
        .quality(85)
        .convert('webp')
        .call(destination: converted_image.path)
    else
      image.format('webp')
      image = image.coalesce
      image.combine_options do |img|
        img.gravity 'center'
        img.quality 85
        # img.auto_orient
        img.strip # EXIF削除
        img.resize resize
        img.extent extent if extent.present?
      end
      image.write(converted_image.path)
    end
    key = "/images/variants/#{variant_type}/#{aid}.webp"
    s3_upload(key: key, file: converted_image.path, content_type: 'image/webp')
    update(variants_column.to_sym => (send(variants_column) + [variant_type]).uniq)
    downloaded_image&.close
    converted_image.close
  end

  def delete_variants(variants_column: 'variants')
    send(variants_column).each do |variant_type|
      s3_delete(key: "/images/variants/#{variant_type}/#{aid}.webp")
    end
    update(variants_column.to_sym => [])
  end

  def delete_original(
    original_ext_column: 'original_ext',
    variants_column: 'variants'
  )
    delete_variants(variants_column: variants_column)
    s3_delete(key: "/images/originals/#{aid}.#{send(original_ext_column)}")
    update(original_ext_column.to_sym => '')
  end

  private

  def varidate_image(
    column_name: 'image',
    required: true,
    max_size_mb: 30,
    max_width: 4096,
    max_height: 4096
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
      if image.width > max_width || image.height > max_height
        errors.add(column_name.to_sym, :image_dimensions_exceeded, max_width: max_width, max_height: max_height)
      end
    rescue MiniMagick::Invalid
      errors.add(column_name.to_sym, :image_invalid)
    end
  end
end
