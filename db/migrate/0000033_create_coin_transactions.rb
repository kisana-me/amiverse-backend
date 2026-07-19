class CreateCoinTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :coin_transactions do |t|
      t.string :aid, null: false
      t.references :account, null: false, foreign_key: true, index: false
      t.bigint :amount, null: false
      t.bigint :balance_after, null: false
      t.integer :kind, null: false, default: 0
      t.string :memo
      t.timestamps
    end
    add_index :coin_transactions, :aid, unique: true
    add_index :coin_transactions, [ :account_id, :created_at ]
  end
end
