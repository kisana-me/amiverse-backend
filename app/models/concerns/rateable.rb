module Rateable
  # レーティング3軸:
  #   user_rating: 投稿者の申告(general / nsfw / r18)
  #   auto_rating: 自動判定(null=未判定。rejectedまで取りうる)
  #   mod_rating : 運営の上書き(null=なし。常に最優先)
  # rating はDBの生成カラム: COALESCE(mod, GREATEST(user, COALESCE(auto, 0)))
  extend ActiveSupport::Concern

  RATINGS = { general: 0, nsfw: 1, r18: 2, rejected: 3 }.freeze
  USER_RATINGS = RATINGS.slice(:general, :nsfw, :r18).freeze

  included do
    enum :user_rating, USER_RATINGS, default: :general, prefix: :user, validate: true
    enum :auto_rating, RATINGS, prefix: :auto, validate: { allow_nil: true }
    enum :mod_rating, RATINGS, prefix: :mod, validate: { allow_nil: true }

    scope :isnt_rejected, -> { where(rating: ...RATINGS[:rejected]) }
    scope :rating_visible_to, ->(account) { where(rating: ..Rateable.max_rating_for(account)) }
  end

  def self.max_rating_for(account)
    account&.adult? ? RATINGS[:r18] : RATINGS[:nsfw]
  end

  def rating_label
    RATINGS.key(rating)&.to_s || "general"
  end

  def rating_rejected?
    rating == RATINGS[:rejected]
  end

  def media_hidden_for?(account)
    rating > Rateable.max_rating_for(account)
  end
end
