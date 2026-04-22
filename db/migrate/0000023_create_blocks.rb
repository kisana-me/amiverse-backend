class CreateBlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :blocks do |t|
      t.references :blocked, null: false, foreign_key: { to_table: :accounts }
      t.references :blocker, null: false, foreign_key: { to_table: :accounts }

      t.timestamps
    end
    add_index :blocks, [ :blocked_id, :blocker_id ], unique: true
  end
end
