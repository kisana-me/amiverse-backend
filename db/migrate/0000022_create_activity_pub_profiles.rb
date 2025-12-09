class CreateActivityPubProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_pub_profiles do |t|
      t.references :account, null: false, foreign_key: true
      t.string :uri, null: false
      t.string :url
      t.string :actor_type, default: 'Person'
      t.string :inbox_url
      t.string :outbox_url
      t.string :shared_inbox_url
      t.string :followers_url
      t.string :following_url
      t.string :featured_url
      t.string :icon_url
      t.string :image_url
      t.text :public_key
      t.text :private_key
      t.datetime :last_fetched_at
      t.json :meta, null: false, default: {}

      t.timestamps
    end
    add_index :activity_pub_profiles, :uri, unique: true
  end
end
