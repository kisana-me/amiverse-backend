class Video < ApplicationRecord
  include VideoProcessable

  belongs_to :account, optional: true
  has_many :post_videos

  attribute :variants, :json, default: -> { [] }
  attribute :meta, :json, default: -> { {} }
  enum :visibility, { opened: 0, limited: 1, closed: 2 }, default: :opened
  enum :status, { normal: 0, locked: 1, deleted: 2 }
  attr_accessor :video

  after_initialize :set_aid, if: :new_record?
  before_create :video_upload
  after_create_commit :enqueue_processing

  validates :name,
    allow_blank: true,
    length: { in: 1..50 }
  validates :description,
    allow_blank: true,
    length: { in: 1..500 }
  validate :video_validation

  scope :from_normal_account, -> { left_joins(:account).where(accounts: { status: :normal }) }
  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }
  scope :is_opened, -> { where(visibility: :opened) }
  scope :isnt_closed, -> { where.not(visibility: :closed) }

  def video_url
    if normal? && variant_type.present?
      object_url(key: "/videos/variants/#{aid}.mp4")
    elsif normal?
      full_url('/static_assets/videos/loading.mp4')
    else
      full_url('/static_assets/videos/amiverse-1.mp4')
    end
  end

  def create_variant(next_variant_type = 'normal')
    return false if original_ext.blank?
    VideoProcessingJob.perform_later(id, next_variant_type)
  end

  def delete_variant
    s3_delete(key: "/videos/variants/#{aid}.mp4")
    self.variant_type = nil
    save
  end

  def delete_original
    s3_delete(key: "/videos/originals/#{aid}.#{original_ext}")
    self.original_ext = nil
    save
  end

  private

  def enqueue_processing
    VideoProcessingJob.perform_later(id)
  end

  def video_upload
    self.name = video.original_filename.split('.').first if name.blank?
    extension = video.original_filename.split('.').last.downcase
    self.original_ext = extension

    s3_upload(
      key: "/videos/originals/#{aid}.#{extension}",
      file: video.path,
      content_type: video.content_type
    )

    # processed_file = video.process_video(input_path: video.path, video: self, variant_type: 'copy')
    # s3_upload(
    #   key: "/videos/variants/#{aid}.mp4",
    #   file: processed_file.path,
    #   content_type: 'video/mp4'
    # )
  end

  def video_validation
    return unless new_record?

    if video.blank?
      errors.add(:video, :blank)
      return
    end

    if video.size > 500.megabytes
      errors.add(:video, 'must be 500MB or less')
    end

    allowed_types = %w[video/mp4 video/quicktime video/x-msvideo video/x-matroska video/webm]
    unless allowed_types.include?(video.content_type)
      errors.add(:video, 'must be a supported video format (mp4, mov, avi, mkv, webm)')
    end

    begin
      movie = FFMPEG::Movie.new(video.path)
      if movie.duration < 3
        errors.add(:video, 'must be at least 3 seconds')
      elsif movie.duration > 5.minutes
        errors.add(:video, 'must be 5 minutes or less')
      end
    rescue StandardError
      errors.add(:video, 'could not be processed')
    end
  end
end
