class CreateDailyVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_visits do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.date :visited_on, null: false
      t.timestamps
    end
    add_index :daily_visits, [ :account_id, :visited_on ], unique: true
  end
end
