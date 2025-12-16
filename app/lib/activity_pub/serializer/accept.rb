module ActivityPub
  module Serializer
    class Accept < Base
      # modelはFollowインスタンス
      # options[:object]にAccept対象のアクティビティ
      def to_h
        {
          '@context': CONTEXT,
          id: "#{actor_uri}/accept/#{SecureRandom.base36(14)}",
          type: 'Accept',
          actor: actor_uri,
          object: object_activity
        }
      end

      private

      def actor_uri
        model.followed.activity_pub_profile.uri
      end

      def object_activity
        options[:object] || ActivityPub::Serializer::Follow.new(model).to_h
      end
    end
  end
end
