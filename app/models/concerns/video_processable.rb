module VideoProcessable
  # VideoProcessable Ver. 1.0.0

  extend ActiveSupport::Concern

  def process_video(input_path:, video:, variant_type:)
    movie = FFMPEG::Movie.new(input_path)
    tempfile = Tempfile.new([SecureRandom.uuid, ".mp4"])
    tempfile.binmode

    options = set_video_options(variant_type)

    if video.nil?
      movie.transcode(tempfile.path, options)
    else
      last_progress = 0.0
      movie.transcode(tempfile.path, options) do |progress|
        if progress - last_progress >= 0.05
          video.meta["progress"] = (progress * 100).to_i
          video.save
          last_progress = progress
        end
      end
      video.meta["progress"] = 100
      video.save
    end

    tempfile
  end

  private

  def set_video_options(variant_type)
    case variant_type
    when 'copy'
      return copy_options
    when 'normal'
      return normal_options
    else
      return normal_options
    end
  end

  def normal_options
    {
      video_codec: 'libx264',
      audio_codec: 'aac',
      custom: [
        "-crf", "24",
        "-preset", "fast",

        "-maxrate", "6M",
        "-bufsize", "12M",

        "-vf", "scale='if(gt(iw,ih),trunc(min(1920,iw)/2)*2,-2)':'if(gt(iw,ih),-2,trunc(min(1920,ih)/2)*2)'",

        "-pix_fmt", "yuv420p",
        "-movflags", "+faststart",
        "-map_metadata", "-1",
        "-profile:v", "high",
        "-level:v", "4.2",

        "-ac", "2",
        "-ar", "44100",
        "-b:a", "128k"
      ]
    }
  end

  def copy_options
    {
      video_codec: 'copy',
      audio_codec: 'copy',
      custom: [
        "-map_metadata", "-1",
        "-movflags", "+faststart"
      ]
    }
  end
end
