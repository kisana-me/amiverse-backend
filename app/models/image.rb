class Image < ApplicationRecord
  include ImageProcessable

  belongs_to :account, optional: true
  has_many :post_images

  attribute :variants, :json, default: -> { [] }
  attribute :meta, :json, default: -> { {} }
  enum :visibility, { opened: 0, limited: 1, closed: 2 }, default: :opened
  enum :status, { normal: 0, locked: 1, deleted: 2 }
  attr_accessor :image, :save_original

  after_initialize :set_aid, if: :new_record?
  before_create :image_upload
  before_save :file_visibility_check

  validates :name,
    allow_blank: true,
    length: { in: 1..50 }
  validates :description,
    allow_blank: true,
    length: { in: 1..500 }

  scope :from_normal_account, -> { left_joins(:account).where(accounts: { status: :normal }) }
  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }
  scope :is_opened, -> { where(visibility: :opened) }
  scope :isnt_closed, -> { where.not(visibility: :closed) }

  def image_url
    if normal? && variant_type.present?
      object_url(key: "/images/variants/#{aid}.webp")
    else
      full_url('/static_assets/images/amiverse-1.webp')
    end
  end

  def image_upload
    validate_image(required: true)

    self.save_original = true
    if save_original
      self.original_ext = image.original_filename.split('.').last.downcase
      s3_upload(
        key: "/images/originals/#{aid}.#{original_ext}",
        file: image.path,
        content_type: image.content_type
      )
    end
    self.name = image.original_filename.split('.').first if name.blank?

    return if deleted?

    self.variant_type = 'normal' if variant_type.blank?
    processed = process_image(image: image, variant_type: variant_type)
    s3_upload(
      key: "/images/variants/#{aid}.webp",
      file: processed.path,
      content_type: 'image/webp'
    )
    processed.delete
  end

  def create_variant(next_variant_type = 'normal')
    return false if original_ext.blank?

    tempfile = Tempfile.new(['tempfile', ".#{original_ext}"])
    tempfile.binmode
    s3_download(
      key: "/images/originals/#{aid}.#{original_ext}",
      response_target: tempfile
    )

    processed = process_image(image: tempfile, variant_type: next_variant_type)
    s3_upload(
      key: "/images/variants/#{aid}.webp",
      file: processed.path,
      content_type: 'image/webp'
    )
    processed.delete
    tempfile.close
    tempfile.unlink

    self.variant_type = next_variant_type
    save
  end

  def delete_variant
    s3_delete(key: "/images/variants/#{aid}.webp")
    self.variant_type = nil
    save
  end

  def delete_original
    s3_delete(key: "/images/originals/#{aid}.#{original_ext}")
    self.original_ext = nil
    save
  end

  private

  def file_visibility_check
    return unless deleted?
    s3_delete(key: "/images/variants/#{aid}.webp")
    self.variant_type = nil
  end
end
