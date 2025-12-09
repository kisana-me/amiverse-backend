class AddActivityPubColumnsToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :uri, :string
    add_column :posts, :url, :string

    add_index :posts, :uri, unique: true
  end
end
