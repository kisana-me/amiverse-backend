class Community < ApplicationRecord
  belongs_to :founder, class_name: "Account", optional: true
  belongs_to :icon, class_name: "Image", foreign_key: "icon_id", optional: true
  belongs_to :banner, class_name: "Image", foreign_key: "banner_id", optional: true
  has_many :posts, dependent: :nullify

  attribute :meta, :json, default: -> { {} }
  enum :visibility, { opened: 0, limited: 1, closed: 2 }, default: :opened
  enum :status, { normal: 0, locked: 1, deleted: 2 }
  attr_accessor :founder_aid

  before_validation :assign_founder_from_aid
  before_create :set_aid

  validates :name,
    presence: true,
    length: { in: 1..50, allow_blank: true }
  validates :description,
    allow_blank: true,
    length: { in: 1..1000 }

  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }
  scope :is_opened, -> { where(visibility: :opened) }
  scope :isnt_closed, -> { where.not(visibility: :closed) }
  scope :listable, -> { where(status: :normal, visibility: :opened) }

  def icon_file=(file)
    if file.present? && file.content_type.start_with?("image/")
      new_image = Image.new
      new_image.image = file
      new_image.variant_type = "icon"
      self.icon = new_image
    end
  end

  def banner_file=(file)
    if file.present? && file.content_type.start_with?("image/")
      new_image = Image.new
      new_image.image = file
      new_image.variant_type = "banner"
      self.banner = new_image
    end
  end

  def icon_url
    icon&.image_url || full_url("/static_assets/images/amiverse-logo.webp")
  end

  def banner_url
    banner&.image_url || full_url("/static_assets/images/amiverse-1.webp")
  end

  private

  def assign_founder_from_aid
    return if founder_aid.nil?

    self.founder = founder_aid.blank? ? nil : Account.find_by(aid: founder_aid)
  end
end
