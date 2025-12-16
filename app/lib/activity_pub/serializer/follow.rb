module ActivityPub
  module Serializer
    class Follow < Base
      # modelはFollowインスタンスを想定
      def to_h
        {
          '@context': CONTEXT,
          id: model.activity_id,
          type: 'Follow',
          actor: actor_uri,
          object: object_uri
        }
      end

      private

      def actor_uri
        model.follower.activity_pub_profile.uri
      end

      def object_uri
        model.followed.activity_pub_profile.uri
      end
    end
  end
end
