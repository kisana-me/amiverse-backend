class AddIndexToPostsAccountCreatedAt < ActiveRecord::Migration[8.1]
  def change
    add_index :posts, [ :account_id, :created_at ]
  end
end
