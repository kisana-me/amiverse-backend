module ActivityPub
  class ProcessInboxJob < ApplicationJob
    queue_as :default

    def perform(payload)
      ActivityPub::InboxService.new(payload).process
    end
  end
end
