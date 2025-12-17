module ActivityPub
  module Process
    class Follow
      def initialize(payload)
        @payload = payload
      end

      def call
        # フォロー元
        actor_uri = @payload['actor']
        remote_account = ActivityPub::Resolve::Actor.by_uri(actor_uri)
        return unless remote_account&.remote?

        # フォロー先
        object_uri = @payload['object']
        local_account = ActivityPub::Resolve::Actor.by_uri(object_uri)
        return unless local_account&.local?

        # Follow
        follow = ::Follow.find_or_initialize_by(follower: remote_account, followed: local_account)
        follow.activity_id =@payload['id']
        follow.save!

        # Accept if auto-accepted
        accept_activity = ActivityPub::Serializer::Accept.new(follow).to_json
        ActivityPub::DeliveryJob.perform_later(
          local_account.id,
          remote_account.activity_pub_profile.inbox_url,
          accept_activity
        )

        # 通知
        NotificationCreator.call(
          actor: remote_account,
          recipient: local_account,
          action: :follow,
        )
      end
    end
  end
end
