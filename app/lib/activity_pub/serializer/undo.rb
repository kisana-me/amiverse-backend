module ActivityPub
  module Serializer
    class Undo < Base
      # modelはFollowインスタンス
      # options[:object]にUndo対象のアクティビティ
      def to_h
        {
          '@context': CONTEXT,
          id: "#{actor_uri}/undo/#{SecureRandom.base36(14)}",
          type: 'Undo',
          actor: actor_uri,
          object: object_activity
        }
      end

      private

      def actor_uri
        model.follower.activity_pub_profile.uri
      end

      def object_activity
        options[:object] || ActivityPub::Serializer::Follow.new(model).to_h
      end
    end
  end
end
