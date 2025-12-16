module ActivityPub
  module Process
    class Undo
      def initialize(json)
        @json = json
      end

      def call
        return unless @json['type'] == 'Undo'

        object = @json['object']

        # フォローの取り消し
        if object.is_a?(Hash) && object['type'] == 'Follow'
          # 取り消し元
          actor_uri = @json['actor']
          remote_account = ActivityPub::Resolve::Actor.by_uri(actor_uri)
          return unless remote_account&.remote?

          # 取り消し先
          local_account = ActivityPub::Resolve::Actor.by_uri(object['object'])
          return unless local_account&.local?

          follow = Follow.find_by(follower: remote_account, followed: local_account)
          if follow
            follow.destroy
            Rails.logger.info "Follow undone (destroyed) for #{remote_account.id} -> #{local_account.id}"
          end
        end
      end
    end
  end
end
