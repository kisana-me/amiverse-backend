class Report < ApplicationRecord
  belongs_to :account, optional: true
  belongs_to :reportable, polymorphic: true

  attribute :meta, :json, default: -> { {} }
  enum :category, {
    other: 0,
    spam: 1,
    hate: 2,
    disinformation: 3,
    violence: 4,
    sensitive: 5,
    suicide:  6,
    illegal: 7,
    theft: 8,
    privacy: 9
  }, default: :other
  enum :status, { normal: 0, locked: 1, deleted: 2 }
  attr_accessor :target_type, :target_aid

  after_initialize :set_aid, if: :new_record?
  before_validation :assign_reportable

  validates :description,
    allow_blank: true,
    length: { in: 1..1000 }
  validates :announcement,
    allow_blank: true,
    length: { in: 1..1000 }

  scope :is_normal, -> { where(status: :normal) }
  scope :isnt_deleted, -> { where.not(status: :deleted) }

  private

  def assign_reportable
    return if target_type.blank? && target_aid.blank?

    case target_type
    when "post"
      self.reportable = Post
        .from_normal_account
        .is_normal
        .is_opened
        .find_by(aid: target_aid)
      if self.reportable.nil?
        errors.add(:base, "通報対象のポストが見つかりませんでした")
        nil
      end
    when "account"
      self.reportable = Account
        .is_normal
        .find_by(aid: target_aid)
      if self.reportable.nil?
        errors.add(:base, "通報対象のアカウントが見つかりませんでした")
        nil
      end
    when "drawing"
      self.reportable = Drawing
        .is_normal
        .find_by(aid: target_aid)
      if self.reportable.nil?
        errors.add(:base, "通報対象のお絵描きが見つかりませんでした")
        nil
      end
    else
      errors.add(:base, "通報対象が見つかりませんでした")
      nil
    end
  end
end
