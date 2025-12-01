class Drawing < ApplicationRecord
  belongs_to :account
  has_many :post_drawings
  has_many :posts, through: :post_drawings

  attribute :meta, :json, default: -> { {} }
  enum :style, { miiverse: 0 }, default: :miiverse
  enum :visibility, { opened: 0, limited: 1, closed: 2 }, default: :opened
  enum :status, { normal: 0, locked: 1, deleted: 2 }

  before_create :set_aid
  after_create :encode_and_upload

  validates :name,
    allow_blank: true,
    length: { in: 1..50 }
  validates :description,
    allow_blank: true,
    length: { in: 1..500 }
  validates :data,
    presence: true

  scope :from_normal_account, -> { joins(:account).where(accounts: { status: :normal }) }
  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }
  scope :is_opened, -> { where(visibility: :opened) }
  scope :isnt_closed, -> { where.not(visibility: :closed) }

  def image_url
    object_url(key: "drawings/#{aid}.png")
  end

  def encode_and_upload
    width = 320
    height = 120

    require 'chunky_png'
    require 'base64'

    # Decode Base64 data
    decoded_data = Base64.decode64(data)
    bytes = decoded_data.bytes

    # Create PNG image
    png = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::WHITE)

    # Set pixels
    (0...height).each do |y|
      (0...width).each do |x|
        i = y * width + x
        byte_index = i / 8
        bit_index = 7 - (i % 8)

        byte = bytes[byte_index] || 0
        is_white = (byte >> bit_index) & 1 == 1

        # 0 = Black, 1 = White
        color = is_white ? ChunkyPNG::Color::WHITE : ChunkyPNG::Color::BLACK
        png[x, y] = color
      end
    end

    # Save to temp file and upload
    Tempfile.create(["drawing_#{aid}", ".png"]) do |file|
      png.save(file.path)

      s3_upload(
        key: "drawings/#{aid}.png",
        file: file.path,
        content_type: 'image/png'
      )
    end
  rescue StandardError => e
    Rails.logger.error("Failed to encode and upload drawing #{aid}: #{e.message}")
  end
end
