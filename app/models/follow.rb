class Follow < ApplicationRecord
  belongs_to :follower, class_name: 'Account'
  belongs_to :followed, class_name: 'Account'
end
