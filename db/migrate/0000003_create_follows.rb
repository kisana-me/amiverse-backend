class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      t.references :followed, null: false, foreign_key: { to_table: :accounts }
      t.references :follower, null: false, foreign_key: { to_table: :accounts }
      t.boolean :accepted, null: false, default: false

      t.timestamps
    end
    add_index :follows, [:followed_id, :follower_id], unique: true
  end
end
