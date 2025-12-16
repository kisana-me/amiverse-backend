module ActivityPub
  class InboxService
    def initialize(json)
      @json = json
    end

    def process
      case @json['type']
      when 'Follow'
        ActivityPub::Process::Follow.new(@json).call
      when 'Undo'
        ActivityPub::Process::Undo.new(@json).call
      when 'Accept'
        ActivityPub::Process::Accept.new(@json).call
      else
        Rails.logger.info "Unhandled ActivityPub type: #{@json['type']}"
      end
    end
  end
end
