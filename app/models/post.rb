class Post < ApplicationRecord
  belongs_to :account
  # 画像 多対多
  belongs_to :reply, class_name: 'Post', optional: true
  has_many   :replies, class_name: 'Post', foreign_key: :reply_id, dependent: :nullify
  belongs_to :quote, class_name: 'Post', optional: true
  has_many   :quotes, class_name: 'Post', foreign_key: :quote_id, dependent: :nullify
  # リアクション 多対多(絵文字)
  has_many :reactions, dependent: :destroy
  has_many :emojis, through: :reactions
  has_many :diffuses, dependent: :destroy
  has_many :diffused_by, through: :diffuses, source: :account

  has_many :post_images
  has_many :images, through: :post_images

  has_many :post_videos
  has_many :videos, through: :post_videos

  attr_accessor :reply_aid, :quote_aid
  attribute :meta, :json, default: -> { {} }
  enum :visibility, { opened: 0, limited: 1, closed: 2 }, default: :opened
  enum :status, { normal: 0, locked: 1, deleted: 2 }

  before_validation :assign_reply_from_aid
  before_validation :assign_quote_from_aid
  before_create :set_aid

  validates :content,
    presence: true,
    length: { in: 1..5000, allow_blank: true }

  scope :from_normal_account, -> { joins(:account).where(accounts: { status: :normal }) }
  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }
  scope :is_opened, -> { where(visibility: :opened) }
  scope :isnt_closed, -> { where.not(visibility: :closed) }

  def media_files=(files)
    files.reject(&:blank?).each do |file|
      if file.content_type.start_with?('image/')
        new_image = Image.new
        new_image.account = self.account
        new_image.image = file
        self.post_images.build(image: new_image)
      elsif file.content_type.start_with?('video/')
        new_video = Video.new
        new_video.account = self.account
        new_video.video = file
        self.post_videos.build(video: new_video)
      end
    end
  end

  private

  def assign_reply_from_aid
    return if reply_aid.blank?
    reply_post = Post
      .from_normal_account
      .isnt_deleted
      .find_by(aid: reply_aid)

    if reply_post.nil?
      errors.add(:reply_aid, 'リプライ先の投稿が見つかりません')
      self.reply = nil
    else
      self.reply = reply_post
    end
  end

  def assign_quote_from_aid
    return if quote_aid.blank?
    quote_post = Post
      .from_normal_account
      .isnt_deleted
      .find_by(aid: quote_aid)

    if quote_post.nil?
      errors.add(:quote_aid, '引用先の投稿が見つかりません')
      self.quote = nil
    else
      self.quote = quote_post
    end
  end
end
