module ActivityPub
  class DeliveryJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: :exponentially_longer, attempts: 5

    def perform(source_account_id, target_inbox_url, activity_json)
      source_account = Account.find(source_account_id)
      ActivityPub::DeliveryService.new(source_account, target_inbox_url, activity_json).perform
    end
  end
end
