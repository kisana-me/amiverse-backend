class AddCoinBalanceToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :coin_balance, :bigint, null: false, default: 0
  end
end
