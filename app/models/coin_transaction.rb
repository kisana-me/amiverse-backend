class CoinTransaction < ApplicationRecord
  belongs_to :account

  enum :kind, { login_bonus: 0, spend: 1, grant: 2, admin_spend: 3, admin_grant: 4 }

  CREDIT_KINDS = %w[login_bonus grant admin_grant].freeze
  DEBIT_KINDS = %w[spend admin_spend].freeze

  before_create :set_aid

  validates :amount, numericality: { other_than: 0 }
  validate :amount_sign_matches_kind

  scope :recent, -> { order(created_at: :desc) }

  private

  def amount_sign_matches_kind
    return if amount.nil? || kind.nil?

    if CREDIT_KINDS.include?(kind) && amount.negative?
      errors.add(:amount, "は受領種別では正の値である必要があります")
    elsif DEBIT_KINDS.include?(kind) && amount.positive?
      errors.add(:amount, "は使用種別では負の値である必要があります")
    end
  end
end
