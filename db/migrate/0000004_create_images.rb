class CreateImages < ActiveRecord::Migration[8.1]
  def change
    create_table :images do |t|
      t.references :account, null: true, foreign_key: true
      t.string :aid, null: false, limit: 14
      t.string :name, null: false, default: ""
      t.text :description, null: false, default: ""
      t.string :original_ext, null: false
      t.json :variants, null: false, default: []
      t.integer :visibility, null: false, limit: 1, default: 0
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0

      t.timestamps
    end
    add_index :images, :aid, unique: true
  end
end
