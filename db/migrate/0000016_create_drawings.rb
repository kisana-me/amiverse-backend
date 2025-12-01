class CreateDrawings < ActiveRecord::Migration[8.1]
  def change
    create_table :drawings do |t|
      t.references :account, null: false, foreign_key: true, type: :bigint
      t.string :aid, null: false, limit: 14
      t.string :name, null: false, default: ""
      t.text :description, null: false, default: ""
      t.text :data, null: false
      t.integer :style, null: false, limit: 1, default: 0
      t.integer :visibility, null: false, limit: 1, default: 0
      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0

      t.timestamps
    end
    add_index :drawings, :aid, unique: true
  end
end
