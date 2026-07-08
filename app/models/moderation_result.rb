class ModerationResult < ApplicationRecord
  belongs_to :moderatable, polymorphic: true
  belongs_to :account, optional: true

  attribute :scores, :json, default: -> { {} }
  enum :rating, Rateable::RATINGS
  enum :source, { auto: 0, manual: 1 }, default: :auto

  validates :classifier, presence: true, if: :auto?

  scope :latest_first, -> { order(id: :desc) }
end
