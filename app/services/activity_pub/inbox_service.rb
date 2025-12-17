module ActivityPub
  class InboxService
    def initialize(payload)
      @payload = payload
    end

    def process
      case @payload['type']
      when 'Create'
        ActivityPub::Process::Create.new(@payload).call
      when 'Follow'
        ActivityPub::Process::Follow.new(@payload).call
      when 'Undo'
        ActivityPub::Process::Undo.new(@payload).call
      when 'Accept'
        ActivityPub::Process::Accept.new(@payload).call
      else
        Rails.logger.info "Unhandled ActivityPub type: #{@payload['type']}"
      end
    end
  end
end
