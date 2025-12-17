module ActivityPub
  module Process
    class Accept
      def initialize(payload)
        @payload = payload
      end

      def call
        # 許可元
        actor_uri = @payload['actor']
        remote_account = ActivityPub::Resolve::Actor.by_uri(actor_uri)
        return unless remote_account&.remote?

        # 許可先
        object = @payload['object']

        # フォローの許可
        if object.is_a?(Hash) && object['type'] == 'Follow'
          local_account = ActivityPub::Resolve::Actor.by_uri(object['actor'])

          if local_account
            follow = ::Follow.find_by(follower: local_account, followed: remote_account)
            if follow
              follow.update!(accepted: true)
              Rails.logger.info "Follow accepted for account #{local_account.id} -> #{remote_account.id}"
            end
          end
        else
          Rails.logger.warn "Received Accept with string object, cannot determine local follower easily without storing Activity IDs."
        end
      end
    end
  end
end
