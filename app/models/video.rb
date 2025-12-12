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
  # after_create_commit :enqueue_processing

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
      object_url(key: "/videos/variants/#{aid}.#{original_ext}")
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
    VideoProcessingJob.set(priority: -10).perform_later(id)
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

    Tempfile.create(['video_clean', ".#{extension}"]) do |temp_file|
      temp_file.close

      movie = FFMPEG::Movie.new(video.path)
      movie.transcode(temp_file.path, { video_codec: 'copy', audio_codec: 'copy', custom: %w[-map_metadata -1] })

      s3_upload(
        key: "/videos/variants/#{aid}.#{extension}",
        file: temp_file.path,
        content_type: video.content_type
      )
    end
  rescue FFMPEG::Error => e
    Rails.logger.error("Metadata removal failed: #{e.message}")
  end

  def video_validation
    return unless new_record?

    if video.blank?
      errors.add(:video, :blank)
      return
    end

    if video.size > 1.gigabyte
      errors.add(:video, 'must be 1GB or less')
    end

    unless video.content_type&.start_with?('video/')
      errors.add(:video, 'must be a video file')
    end
  end
end
