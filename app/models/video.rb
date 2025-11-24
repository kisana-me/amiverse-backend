class Video < ApplicationRecord
  belongs_to :account, optional: true
  has_many :post_videos

  attribute :variants, :json, default: -> { [] }
  attribute :meta, :json, default: -> { {} }
  enum :visibility, { closed: 0, limited: 1, opened: 2 }, default: :opened
  enum :status, { normal: 0, locked: 1, deleted: 2 }
  attr_accessor :video

  after_initialize :set_aid, if: :new_record?
  before_create :video_upload

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

  def video_url(variant_type: 'normal')
    return '/no-video.png' unless normal?

    # process_video(variant_type: variant_type) if variants.exclude?(variant_type) && original_ext.present?
    object_url(key: "/videos/originals/#{aid}.#{original_ext}")
  end

  private

  def video_upload
    self.name = video.original_filename.split('.').first if name.blank?
    extension = video.original_filename.split('.').last.downcase
    self.original_ext = extension
    s3_upload(
      key: "/videos/originals/#{aid}.#{extension}",
      file: video.path,
      content_type: video.content_type
    )
  end

  def video_validation
    return unless new_record?
    # Add validation logic here if needed
  end
end
