module ActivityPub
  module Serializer
    class Note < Base
      def to_h
        {
          '@context': CONTEXT,
          id: object_uri,
          type: 'Note',
          summary: nil,
          published: model.created_at.iso8601,
          url: object_uri,
          attributedTo: actor_uri,
          to: to_audience,
          cc: cc_audience,
          content: model.content
        }
      end

      private

      def object_uri
        "#{actor_uri}/posts/#{model.aid}"
      end

      def actor_uri
        model.account.activity_pub_profile.uri
      end

      def to_audience
        ['https://www.w3.org/ns/activitystreams#Public']
      end

      def cc_audience
        [model.account.activity_pub_profile.followers_url]
      end
    end
  end
end
