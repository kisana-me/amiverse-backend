module ActivityPub
  module Serializer
    class Create < Base
      def to_h
        note_serializer = ActivityPub::Serializer::Note.new(model)
        note_object = note_serializer.to_h

        {
          '@context': CONTEXT,
          id: "#{note_object[:id]}/create",
          type: 'Create',
          actor: note_object[:attributedTo],
          published: note_object[:published],
          to: note_object[:to],
          cc: note_object[:cc],
          object: note_object
        }
      end
    end
  end
end
