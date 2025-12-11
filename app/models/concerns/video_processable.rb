module VideoProcessable
  extend ActiveSupport::Concern

  def process_video(input_path:, variant_type:)
    movie = FFMPEG::Movie.new(input_path)
    output_path = "#{File.dirname(input_path)}/#{SecureRandom.uuid}.mp4"

    options = set_video_options(variant_type, movie)

    movie.transcode(output_path, options)

    File.open(output_path)
  end

  private

  def set_video_options(variant_type, movie)
    options = {
      video_codec: 'libx264',
      audio_codec: 'aac',
      custom: %w[-movflags +faststart -pix_fmt yuv420p]
    }

    case variant_type
    when 'normal'
      if movie.width > 1920 || movie.height > 1080
        options[:resolution] = '1920x1080'
      end
    when '480p'
      options[:resolution] = '854x480'
      options[:video_bitrate] = 1000
    else
    end

    options
  end
end
