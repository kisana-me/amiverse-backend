class Emoji < ApplicationRecord
  belongs_to :image, optional: true

  attribute :meta, :json, default: -> { {} }
  enum :status, { normal: 0, locked: 1, deleted: 2 }
  attr_accessor :image_aid

  after_initialize :set_aid, if: :new_record?
  # before_create :image_upload

  validates :name,
    allow_blank: true,
    length: { in: 1..100 }
  validates :name_id,
    presence: true,
    length: { in: 1..100, allow_blank: true },
    format: { with: NAME_ID_REGEX, allow_blank: true },
    uniqueness: { case_sensitive: false, allow_blank: true }
  validates :description,
    allow_blank: true,
    length: { in: 1..500 }

  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }

  def image_url
    image&.image_url(variant_type: 'emoji') || full_url('/static_assets/images/amiverse-logo.png')
  end

  private

  def image_upload
    self.name = image.original_filename.split('.').first if name.blank?
    extension = image.original_filename.split('.').last.downcase
    self.original_ext = extension
    s3_upload(
      key: "/images/originals/#{aid}.#{extension}",
      file: image.path,
      content_type: image.content_type
    )
  end
end
