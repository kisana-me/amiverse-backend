class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :aid, null: false, limit: 14
      t.string :name, null: false
      t.string :name_id, null: false
      t.text :description, null: false, default: ""
      t.datetime :birthdate, null: true
      t.string :email, null: true
      t.boolean :email_verified, null: false, default: false
      t.integer :visibility, limit: 1, null: false, default: 0
      t.string :password_digest, null: true
      t.json :meta, null: false, default: {}
      t.integer :status, limit: 1, null: false, default: 0

      t.timestamps
    end
    add_index :accounts, :aid, unique: true
    add_index :accounts, :name_id, unique: true
    add_index :accounts, :email, unique: true
  end
end
