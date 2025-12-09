class CreateActivityPubInstances < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_pub_instances do |t|
      t.string :domain, null: false

      t.string :software_name
      t.string :software_version
      t.string :software_homepage
      t.string :software_repository

      t.string :name
      t.text :description
      t.string :icon_url
      t.string :favicon_url
      t.string :theme_color
      t.string :maintainer_name
      t.string :maintainer_email

      t.boolean :open_registrations, default: false
      t.integer :users, null: false, default: 0
      t.integer :posts, null: false, default: 0
      t.integer :followers, null: false, default: 0
      t.integer :following, null: false, default: 0

      t.datetime :first_retrieved_at
      t.datetime :last_received_at
      t.datetime :last_fetched_at

      t.json :meta, null: false, default: {}
      t.integer :status, null: false, limit: 1, default: 0

      t.timestamps
    end
    add_index :activity_pub_instances, :domain, unique: true

    add_reference :accounts, :activity_pub_instance, foreign_key: true
  end
end
