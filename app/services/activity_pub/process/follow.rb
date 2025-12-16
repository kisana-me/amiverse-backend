module ActivityPub
  module Process
    class Follow
      def initialize(json)
        @json = json
      end

      def call
        return unless @json['type'] == 'Follow'

        # フォロー元
        actor_uri = @json['actor']
        remote_account = ActivityPub::Resolve::Actor.by_uri(actor_uri)
        return unless remote_account&.remote?

        # フォロー先
        object_uri = @json['object']
        local_account = ActivityPub::Resolve::Actor.by_uri(object_uri)
        return unless local_account&.local?

        # Follow
        follow = Follow.find_or_initialize_by(follower: remote_account, followed: local_account)
        follow.save!

        # Accept if auto-accepted
        # accept_activity = ActivityPub::Serializer::Accept.new(follow).to_json
        # ActivityPub::DeliveryJob.perform_later(
        #   local_account.id,
        #   remote_profile.inbox_url,
        #   accept_activity
        # )

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
