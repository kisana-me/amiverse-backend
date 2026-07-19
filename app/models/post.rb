class Post < ApplicationRecord
  include MeiliSearch::Rails
  include Rateable

  belongs_to :account
  belongs_to :community, optional: true

  belongs_to :reply, -> { from_normal_account.is_normal.is_opened }, class_name: "Post", optional: true
  has_many   :replies, -> { from_normal_account.is_normal.is_opened }, class_name: "Post", foreign_key: :reply_id
  has_many   :all_replies, class_name: "Post", foreign_key: :reply_id, dependent: :nullify

  belongs_to :quote, -> { from_normal_account.is_normal.is_opened }, class_name: "Post", optional: true
  has_many   :quotes, -> { from_normal_account.is_normal.is_opened }, class_name: "Post", foreign_key: :quote_id
  has_many   :all_quotes, class_name: "Post", foreign_key: :quote_id, dependent: :nullify

  # リアクション 多対多(絵文字)
  has_many :reactions, dependent: :destroy
  has_many :emojis, through: :reactions
  has_many :diffuses, dependent: :destroy
  has_many :diffused_by, through: :diffuses, source: :account

  has_many :post_images
  has_many :images, through: :post_images

  has_many :post_videos
  has_many :videos, through: :post_videos

  has_many :post_drawings
  has_many :drawings, through: :post_drawings

  has_many :notifications, as: :notifiable, dependent: :destroy
  has_many :moderation_results, as: :moderatable, dependent: :destroy

  attr_accessor :reply_aid, :quote_aid, :community_aid
  attribute :meta, :json, default: -> { {} }
  enum :visibility, { opened: 0, limited: 1, closed: 2 }, default: :opened
  enum :status, { normal: 0, locked: 1, deleted: 2 }

  before_validation :assign_reply_from_aid
  before_validation :assign_quote_from_aid
  before_validation :assign_community_from_aid
  before_create :set_aid
  before_create :rate_content_text

  validates :content, length: { maximum: 5000, allow_blank: true }
  validates :content, presence: true, unless: :media_attached?
  validate :validate_media_files

  scope :from_normal_account, -> { joins(:account).where(accounts: { status: :normal }) }
  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }
  scope :is_opened, -> { where(visibility: :opened) }
  scope :isnt_closed, -> { where.not(visibility: :closed) }

  scope :with_associations, -> {
    preload(
      :diffuses,
      :images,
      :videos,
      :drawings,
      reply: :account,
      quote: :account,
      replies: :account,
      quotes: :account,
      reactions: :emoji,
      account: :icon
    )
  }

  meilisearch do
    attribute :content
    attribute :status
    attribute :visibility
    attribute :rating
    attribute :account_status do
      account&.status
    end
    filterable_attributes [ :created_at, :status, :visibility, :account_status, :rating ]
    sortable_attributes [ :created_at ]
  end

  # レーティング等の指定なしでファイルだけ添付する場合(後方互換)
  def media_files=(files)
    Array(files).reject(&:blank?).each do |file|
      build_medium(file: file)
    end
  end

  # 画像・動画をファイルごとに rating / name / description 付きで添付する
  # 期待する形: [{ file:, rating:, name:, description: }, ...]
  def media_attributes=(attributes)
    return if attributes.blank?

    collection = attributes.is_a?(Array) ? attributes : attributes.values
    collection.each do |attrs|
      file = attrs[:file] || attrs["file"]
      next if file.blank?

      build_medium(
        file: file,
        rating: attrs[:rating] || attrs["rating"],
        name: attrs[:name] || attrs["name"],
        description: attrs[:description] || attrs["description"]
      )
    end
  end

  def drawing_attributes=(attributes)
    return if attributes.blank?

    attributes_collection = attributes.is_a?(Array) ? attributes : [ attributes ]

    attributes_collection.each do |attrs|
      data = attrs[:data] || attrs["data"]
      next if data.blank?

      new_drawing = Drawing.new
      new_drawing.account = self.account
      new_drawing.data = data
      new_drawing.name = attrs[:name] || attrs["name"] || ""
      new_drawing.description = attrs[:description] || attrs["description"] || ""
      rating = attrs[:rating] || attrs["rating"]
      new_drawing.user_rating = rating if rating.present?
      self.post_drawings.build(drawing: new_drawing)
    end
  end

  private

  def build_medium(file:, rating: nil, name: nil, description: nil)
    if file.content_type.start_with?("image/")
      medium = Image.new(account: self.account, name: name.to_s, description: description.to_s)
      medium.user_rating = rating if rating.present?
      medium.image = file
      self.post_images.build(image: medium)
    elsif file.content_type.start_with?("video/")
      medium = Video.new(account: self.account, name: name.to_s, description: description.to_s)
      medium.user_rating = rating if rating.present?
      medium.video = file
      self.post_videos.build(video: medium)
    else
      @media_upload_error = "サポートされていないメディアタイプです"
    end
  end

  def rate_content_text
    self.auto_rating = TextRating.rate(content) if read_attribute_before_type_cast(:auto_rating).nil?
  end

  def assign_reply_from_aid
    return if reply_aid.blank?
    reply_post = Post
      .from_normal_account
      .isnt_deleted
      .find_by(aid: reply_aid)

    if reply_post.nil?
      errors.add(:reply_aid, "リプライ先の投稿が見つかりません")
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
      errors.add(:quote_aid, "引用先の投稿が見つかりません")
      self.quote = nil
    else
      self.quote = quote_post
    end
  end

  def assign_community_from_aid
    return if community_aid.blank?

    self.community = Community.listable.find_by(aid: community_aid)
  end

  def media_attached?
    post_images.present? || post_videos.present? || post_drawings.present?
  end

  def validate_media_files
    if @media_upload_error
      errors.add(:base, @media_upload_error)
    end

    media_objects = post_images.map(&:image) + post_videos.map(&:video)

    media_objects.compact.each do |media|
      next if media.valid?

      media.errors.full_messages.each do |msg|
        errors.add(:base, msg)
      end
    end
  end
end
