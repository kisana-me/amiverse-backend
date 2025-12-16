module ActivityPub
  module Serializer
    class Base
      CONTEXT = [
        'https://www.w3.org/ns/activitystreams',
        'https://w3id.org/security/v1'
      ].freeze

      def initialize(model, options = {})
        @model = model
        @options = options
      end

      def to_json
        to_h.to_json
      end

      def to_h
        raise NotImplementedError
      end

      protected

      attr_reader :model, :options
    end
  end
end
