class CreatePostDrawings < ActiveRecord::Migration[8.1]
  def change
    create_table :post_drawings do |t|
      t.references :post, null: false, foreign_key: true
      t.references :drawing, null: false, foreign_key: true

      t.timestamps
    end
  end
end
