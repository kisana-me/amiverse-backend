class Reaction < ApplicationRecord
  belongs_to :account
  belongs_to :post
  belongs_to :emoji
end
