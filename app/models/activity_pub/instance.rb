module ActivityPub
  class Instance < ApplicationRecord
    self.table_name = 'activity_pub_instances'

    has_many :accounts, class_name: '::Account', foreign_key: 'activity_pub_instance_id'

    validates :domain, presence: true, uniqueness: true
  end
end
