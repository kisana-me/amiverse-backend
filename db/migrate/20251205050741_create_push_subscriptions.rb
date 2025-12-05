class CreatePushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :push_subscriptions do |t|
      t.references :account, null: false, foreign_key: true
      t.text :endpoint
      t.string :p256dh
      t.string :auth_key

      t.timestamps
    end
  end
end
