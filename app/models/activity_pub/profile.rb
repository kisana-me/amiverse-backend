module ActivityPub
  class Profile < ApplicationRecord
    self.table_name = 'activity_pub_profiles'

    belongs_to :account, class_name: '::Account'

    validates :uri, presence: true, uniqueness: true
    validates :inbox_url, presence: true
  end
end
