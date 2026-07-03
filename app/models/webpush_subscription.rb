class WebpushSubscription < ApplicationRecord
  belongs_to :account

  attribute :meta, :json, default: -> { {} }
  enum :status, { normal: 0, locked: 1, deleted: 2 }

  validates :endpoint, presence: true
  validates :p256dh, presence: true
  validates :auth_key, presence: true
  validates :name,
    allow_blank: true,
    length: { in: 1..50 }

  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }

  # User-Agentから「ブラウザ (OS)」形式の端末名を生成する
  def self.device_name_for(user_agent)
    ua = user_agent.to_s

    browser =
      if ua.match?(%r{Edg(e|A|iOS)?/})
        "Edge"
      elsif ua.match?(%r{OPR/|Opera})
        "Opera"
      elsif ua.match?(%r{SamsungBrowser/})
        "Samsung Internet"
      elsif ua.match?(%r{(Firefox|FxiOS)/})
        "Firefox"
      elsif ua.match?(%r{(Chrome|CriOS)/})
        "Chrome"
      elsif ua.include?("Safari")
        "Safari"
      end

    os =
      if ua.include?("iPhone")
        "iPhone"
      elsif ua.include?("iPad")
        "iPad"
      elsif ua.include?("Android")
        "Android"
      elsif ua.include?("Windows")
        "Windows"
      elsif ua.include?("Macintosh") || ua.include?("Mac OS X")
        "Mac"
      elsif ua.include?("CrOS")
        "ChromeOS"
      elsif ua.include?("Linux")
        "Linux"
      end

    if browser && os
      "#{browser} (#{os})"
    else
      browser || os || "不明な端末"
    end
  end
end
