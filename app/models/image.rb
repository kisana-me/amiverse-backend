class Image < ApplicationRecord
  belongs_to :account, optional: true

  attribute :variants, :json, default: -> { [] }
  attribute :meta, :json, default: -> { {} }
  enum :visibility, { closed: 0, limited: 1, opened: 2 }, default: :opened
  enum :status, { normal: 0, locked: 1, deleted: 2 }
  attr_accessor :image

  after_initialize :set_aid, if: :new_record?
  before_create :image_upload

  validates :name,
    allow_blank: true,
    length: { in: 1..50 }
  validates :description,
    allow_blank: true,
    length: { in: 1..500 }
  validate :image_varidation

  scope :from_normal_account, -> { left_joins(:account).where(accounts: { status: :normal }) }
  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }
  scope :is_opened, -> { where(visibility: :opened) }
  scope :isnt_closed, -> { where.not(visibility: :closed) }

  def image_url(variant_type: 'normal')
    return '/no-image.png' unless normal?

    process_image(variant_type: variant_type) if variants.exclude?(variant_type) && original_ext.present?
    object_url(key: "/images/variants/#{variant_type}/#{aid}.webp")
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

  def image_varidation
    return unless new_record?

    varidate_image(required: true)
  end
end
