class CreateCommunities < ActiveRecord::Migration[8.1]
  def change
    create_table :communities do |t|
      t.string :aid, null: false, limit: 14
      t.string :name
      t.text :description
      t.references :founder, null: true, foreign_key: { to_table: :accounts }
      t.references :icon, null: true, foreign_key: { to_table: :images }
      t.references :banner, null: true, foreign_key: { to_table: :images }
      t.integer :visibility, null: false, limit: 1, default: 0
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0

      t.timestamps
    end
    add_index :communities, :aid, unique: true
  end
end
