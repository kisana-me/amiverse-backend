class OauthAccount < ApplicationRecord
  belongs_to :account

  enum :provider, { anyur: 0 }
  enum :status, { normal: 0, locked: 1, deleted: 2 }

  before_create :set_aid

  validates :provider,
    presence: true,
    length: { in: 1..150, allow_blank: true }
  validates :uid,
    presence: true,
    length: { in: 1..250, allow_blank: true }

  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }
end
