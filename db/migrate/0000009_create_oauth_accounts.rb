class CreateOauthAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_accounts do |t|
      t.string :aid, null: false, limit: 14
      t.references :account, null: false, foreign_key: true
      t.integer :provider, limit: 1, null: false
      t.string :uid, null: false
      t.text :access_token, null: false
      t.text :refresh_token, null: false
      t.datetime :expires_at, null: false
      t.datetime :fetched_at, null: false
      t.json :meta, null: false, default: {}
      t.integer :status, limit: 1, null: false, default: 0

      t.timestamps
    end
    add_index :oauth_accounts, :aid, unique: true
    add_index :oauth_accounts, [:provider, :uid], unique: true
  end
end
