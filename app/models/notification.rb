class Notification < ApplicationRecord
  belongs_to :account
  belongs_to :actor, class_name: 'Account', optional: true
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :action, {
    # General
    system: 0,
    # Post related
    reaction: 11,
    diffuse: 12,
    reply: 13,
    quote: 14,
    # Account related
    follow: 21,
    mention: 22,
    # Session related
    signin: 31
  }
  enum :status, { normal: 0, locked: 1, deleted: 2 }

  before_validation :set_aid, on: :create

  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(checked: false) }
  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }
  scope :with_details, -> { includes(:actor, :notifiable) }

  def post_related?
    ['reaction', 'diffuse', 'reply', 'quote'].include?(action)
  end

  def account_related?
    ['follow', 'mention'].include?(action)
  end
end
