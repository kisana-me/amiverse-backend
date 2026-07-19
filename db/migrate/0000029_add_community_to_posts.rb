class AddCommunityToPosts < ActiveRecord::Migration[8.1]
  def change
    add_reference :posts, :community, null: true, foreign_key: true
  end
end
