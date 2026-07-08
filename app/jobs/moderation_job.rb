class ModerationJob < ApplicationJob
  queue_as :default

  VIDEO_FRAME_COUNT = 12

  def self.enabled?
    ENV["MODERATION_ENDPOINT"].present?
  end

  def perform(type, id)
    return unless self.class.enabled?

    record = { "Image" => Image, "Video" => Video, "Drawing" => Drawing }[type]&.find_by(id: id)
    return unless record
    return if record.deleted?

    tempfiles = collect_files(record)
    return if tempfiles.empty?

    begin
      result = classify(tempfiles)
      apply_result(record, result) if result
    ensure
      tempfiles.each do |file|
        file.close
        file.unlink
      rescue StandardError
        nil
      end
    end
  end

  private

  def collect_files(record)
    case record
    when Image
      return [] if record.variant_type.blank?
      [ download(record, "/images/variants/#{record.aid}.webp", ".webp") ].compact
    when Drawing
      [ download(record, "drawings/#{record.aid}.png", ".png") ].compact
    when Video
      video_frames(record)
    else
      []
    end
  end

  def download(record, key, ext)
    tempfile = Tempfile.new([ "moderation", ext ])
    tempfile.binmode
    record.s3_download(key: key, response_target: tempfile)
    tempfile
  rescue Aws::S3::Errors::NoSuchKey
    tempfile.close
    tempfile.unlink
    nil
  end

  def video_frames(video)
    source_key = if video.variant_type.present?
      "/videos/variants/#{video.aid}.mp4"
    else
      "/videos/originals/#{video.aid}.#{video.original_ext}"
    end
    source = download(video, source_key, File.extname(source_key))
    return [] unless source

    begin
      movie = FFMPEG::Movie.new(source.path)
      duration = movie.duration.to_f
      return [] if duration <= 0

      Array.new(VIDEO_FRAME_COUNT) { |i| duration * (i + 0.5) / VIDEO_FRAME_COUNT }.filter_map do |seek_time|
        frame = Tempfile.new([ "moderation_frame", ".jpg" ])
        frame.binmode
        movie.screenshot(frame.path, seek_time: seek_time)
        frame
      rescue StandardError
        frame.close
        frame.unlink
        nil
      end
    ensure
      source.close
      source.unlink
    end
  end

  def classify(tempfiles)
    uri = URI.parse("#{ENV.fetch('MODERATION_ENDPOINT')}/classify")
    form = tempfiles.map { |file| [ "files", File.open(file.path) ] }

    request = Net::HTTP::Post.new(uri)
    request.set_form(form, "multipart/form-data")

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 15, read_timeout: 120) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("ModerationJob: sidecar returned #{response.code}")
      raise "moderation sidecar error: #{response.code}"
    end

    JSON.parse(response.body)
  ensure
    form&.each { |_, io| io.close rescue nil }
  end

  def apply_result(record, result)
    rating = result["rating"].to_s
    return unless Rateable::RATINGS.key?(rating.to_sym)

    record.update!(auto_rating: rating)
    record.moderation_results.create!(
      classifier: result["classifier"].presence || "moderation-sidecar",
      rating: rating,
      scores: result,
      source: :auto
    )
  end
end
