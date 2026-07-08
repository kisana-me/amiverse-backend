class CreateModerationResults < ActiveRecord::Migration[8.1]
  def change
    create_table :moderation_results do |t|
      t.references :moderatable, null: false, polymorphic: true
      t.references :account, null: true, foreign_key: true
      t.string :classifier, null: false, default: ""
      t.integer :rating, null: false, limit: 1
      t.json :scores, null: false, default: {}
      t.integer :source, null: false, limit: 1, default: 0

      t.timestamps
    end
  end
end
