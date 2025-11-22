class CreateEmojis < ActiveRecord::Migration[8.1]
  def change
    create_table :emojis do |t|
      t.references :image, null: true, foreign_key: true
      t.string :aid, null: false
      t.string :name, null: false, default: ""
      t.string :name_id, null: false
      t.text :description, null: false, default: ""
      t.string :group, null: false, default: ""
      t.string :subgroup, null: false, default: ""
      t.json :meta, null: false, default: {}
      t.integer :status, limit: 1, null: false, default: 0

      t.timestamps
    end
    add_index :emojis, :aid, unique: true
    add_index :emojis, :name_id, unique: true
    add_index :emojis, :group
    add_index :emojis, :subgroup
  end
end
