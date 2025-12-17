module ActivityPub
  module Process
    class Create
      def initialize(payload)
        @payload = payload
      end

      def call
        object = @payload['object']
        return unless object.is_a?(Hash) && object['type'] == 'Note'

        actor_uri = @payload['actor']
        account = ActivityPub::Resolve::Actor.by_uri(actor_uri)
        return unless account

        # 重複チェック
        return if ::Post.exists?(uri: object['id'])

        content = object['content'] || ''
        content = content.gsub(/<br\s*\/?>/i, "\n")
        content = content.gsub(/<\/p>/i, "\n\n")
        content = ActionController::Base.helpers.strip_tags(content)
        content = CGI.unescapeHTML(content).strip

        ::Post.create!(
          account: account,
          content: content,
          uri: object['id']
        )
      end
    end
  end
end
