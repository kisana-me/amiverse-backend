class Account < ApplicationRecord
  has_many :sessions
  has_many :posts, dependent: :destroy
  has_many :images
  has_many :videos
  belongs_to :icon, class_name: 'Image', foreign_key: 'icon_id', optional: true
  belongs_to :banner, class_name: 'Image', foreign_key: 'banner_id', optional: true
  has_many :oauth_accounts
  has_many :active_relationships, class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy
  has_many :passive_relationships, class_name: 'Follow', foreign_key: 'followed_id', dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower
  has_many :diffuses, dependent: :destroy
  has_many :diffused_posts, through: :diffuses, source: :post

  attribute :meta, :json, default: -> { {} }
  enum :visibility, { opened: 0, limited: 1, closed: 2 }, default: :opened
  enum :status, { normal: 0, locked: 1, deleted: 2 }
  attr_accessor :icon_aid

  before_create :set_aid

  validates :name,
    presence: true,
    length: { in: 1..50, allow_blank: true }
  validates :name_id,
    presence: true,
    length: { in: 5..50, allow_blank: true },
    format: { with: NAME_ID_REGEX, allow_blank: true },
    uniqueness: { case_sensitive: false, allow_blank: true }
  validates :description,
    allow_blank: true,
    length: { in: 1..500 }
  validates :email,
    length: { maximum: 255, allow_blank: true },
    format: { with: VALID_EMAIL_REGEX, allow_blank: true },
    uniqueness: { case_sensitive: false, allow_blank: true }
  has_secure_password validations: false
  validates :password,
    allow_blank: true,
    length: { in: 8..30 },
    confirmation: true

  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }
  scope :is_opened, -> { where(visibility: :opened) }
  scope :isnt_closed, -> { where.not(visibility: :closed) }

  def icon_file=(file)
    if file.present? && file.content_type.start_with?('image/')
      new_icon = Image.new
      new_icon.account = self
      new_icon.image = file
      self.icon = new_icon
    end
  end

  def banner_file=(file)
    if file.present? && file.content_type.start_with?('image/')
      new_banner = Image.new
      new_banner.account = self
      new_banner.image = file
      self.banner = new_banner
    end
  end

  def icon_url
    icon&.image_url(variant_type: 'icon') || full_url('/static_assets/images/amiverse-logo.png')
  end

  def banner_url
    banner&.image_url(variant_type: 'banner') || full_url('/static_assets/images/amiverse-1.png')
  end

  def subscription_plan
    status = meta.dig('subscription', 'subscription_status')
    return :basic unless %w[active trialing].include?(status)

    period_end = meta.dig('subscription', 'current_period_end')&.to_time
    return :expired unless period_end && period_end > Time.current

    plan = meta.dig('subscription', 'plan')
    plan&.to_sym || :unknown
  end

  def admin?
    self.meta['roles']&.include?('admin')
  end

  private

  def assign_icon
    return if icon_aid.blank?

    self.icon = Image.find_by(
      account: self,
      aid: icon_aid
    )
  end
end
