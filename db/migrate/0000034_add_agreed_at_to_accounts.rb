class AddAgreedAtToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :agreed_at, :datetime
  end
end
