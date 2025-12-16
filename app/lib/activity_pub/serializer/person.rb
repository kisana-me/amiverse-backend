module ActivityPub
  module Serializer
    class Person < Base
      def to_h
        app = model.activity_pub_profiles
        {
          '@context': CONTEXT,
          id: app.uri,
          type: 'Person',
          following: app.following_url,
          followers: app.followers_url,
          inbox: app.inbox_url,
          outbox: app.outbox_url,
          preferredUsername: model.name_id,
          name: model.name,
          summary: model.description,
          url: app.url,
          publicKey: {
            id: "#{app.uri}#main-key",
            owner: app.uri,
            publicKeyPem: app.public_key
          },
          icon: icon_object,
          image: image_object
        }.compact
      end

      private

      def icon_object
        return nil
        #  unless model.icon
        # {
        #   type: 'Image',
        #   mediaType: 'image/webp',
        #   url: model.icon_url
        # }
      end

      def image_object
        return nil
        #  unless model.banner
        # {
        #   type: 'Image',
        #   mediaType: 'image/webp',
        #   url: model.banner_url
        # }
      end
    end
  end
end
