class CreateNotificationSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_settings do |t|
      t.references :account, null: false, foreign_key: true

      # Post related
      t.boolean :reaction, null: false, default: true
      t.boolean :diffuse, null: false, default: true
      t.boolean :reply, null: false, default: true
      t.boolean :quote, null: false, default: true
      # Account related
      t.boolean :follow, null: false, default: true
      t.boolean :mention, null: false, default: true

      t.timestamps
    end
  end
end
