class ChangeAddIconToAccounts < ActiveRecord::Migration[8.1]
  def change
    change_table :accounts do |t|
      t.references :icon, null: true, foreign_key: { to_table: :images }
    end
  end
end
