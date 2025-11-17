class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :account, null: false, foreign_key: true
      t.references :reply, null: true, foreign_key: { to_table: :posts }
      t.references :quote, null: true, foreign_key: { to_table: :posts }
      t.string :aid, null: false, limit: 14
      t.text :content, null: false, default: ""
      t.integer :visibility, null: false, limit: 1, default: 0
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0

      t.timestamps
    end
    add_index :posts, :aid, unique: true
  end
end
