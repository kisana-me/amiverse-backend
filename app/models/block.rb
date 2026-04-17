class Block < ApplicationRecord
  belongs_to :blocker, class_name: 'Account'
  belongs_to :blocked, class_name: 'Account'
end
