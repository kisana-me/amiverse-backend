class WebpushSubscription < ApplicationRecord
  belongs_to :account

  validates :endpoint, presence: true
  validates :p256dh, presence: true
  validates :auth_key, presence: true
end
