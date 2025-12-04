class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :account, null: false, foreign_key: true
      t.references :actor, null: true, foreign_key: { to_table: :accounts }
      t.references :notifiable, null: true, polymorphic: true
      t.string :aid, null: false, limit: 14
      t.integer :action, null: false, limit: 1, default: 0
      t.string :content, null: true, default: ""
      t.boolean :checked, null: false, default: false
      t.integer :status, null: false, limit: 1, default: 0

      t.timestamps
    end
    add_index :notifications, :aid, unique: true
  end
end
