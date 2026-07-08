class AddRatingPreferencesToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :reveal_sensitive, :boolean, null: false, default: false
  end
end
