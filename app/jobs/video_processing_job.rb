class VideoProcessingJob < ApplicationJob
  queue_as :default

  def perform(video_id, variant_type = 'normal')
    video = Video.find_by(id: video_id)
    return unless video

    # オリジナル動画をダウンロード
    original_key = "/videos/originals/#{video.aid}.#{video.original_ext}"
    temp_input = Tempfile.new(['original', ".#{video.original_ext}"])
    temp_input.binmode

    begin
      video.s3_download(key: original_key, response_target: temp_input)
    rescue Aws::S3::Errors::NoSuchKey
      Rails.logger.error "Video original file not found: #{original_key}"
      temp_input.close
      temp_input.unlink
      return
    end

    begin
      processed_file = video.process_video(input_path: temp_input.path, video: video, variant_type: variant_type)

      upload_key = if variant_type == 'normal'
                     "/videos/variants/#{video.aid}.mp4"
                   else
                     "/videos/variants/#{variant_type}/#{video.aid}.mp4"
                   end

      video.send(:s3_upload,
        key: upload_key,
        file: processed_file.path,
        content_type: 'video/mp4'
      )

      # バリアント情報の更新
      variants = video.variants || []
      unless variants.include?(variant_type)
        variants << variant_type
      end

      video.variant_type = variant_type
      video.variants = variants
      video.save!

    ensure
      # 後始末
      if processed_file
        processed_file.close
        File.delete(processed_file.path) if File.exist?(processed_file.path)
      end
      temp_input.close
      temp_input.unlink
    end
  end
end
