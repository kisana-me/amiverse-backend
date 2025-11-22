class Diffuse < ApplicationRecord
  belongs_to :account
  belongs_to :post

  validates :account_id, uniqueness: { scope: :post_id }
end
