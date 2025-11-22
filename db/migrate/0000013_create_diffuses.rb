class CreateDiffuses < ActiveRecord::Migration[8.1]
  def change
    create_table :diffuses do |t|
      t.references :account, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end
  end
end
