class Session < ApplicationRecord
  belongs_to :account

  attribute :meta, :json, default: -> { {} }
  enum :status, { normal: 0, locked: 1, deleted: 2 }

  before_create :set_aid

  validates :name,
    allow_blank: true,
    length: { in: 1..50 }

  scope :from_normal_account, -> { joins(:account).where(accounts: { status: :normal }) }
  scope :from_not_deleted_account, -> { joins(:account).where.not(accounts: { status: :deleted }) }
  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }
end
