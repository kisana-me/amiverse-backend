module ActivityPub
  class ProcessInboxJob < ApplicationJob
    queue_as :default

    def perform(body)
      json = JSON.parse(body)
      ActivityPub::InboxService.new(json).process
    end
  end
end
