class AddActivitypubIdsToFollows < ActiveRecord::Migration[8.1]
  def change
    add_column :follows, :activity_id, :string, comment: 'Remote ActivityPub activity id (e.g. the Follow activity id)'

    add_index :follows, :activity_id
  end
end
