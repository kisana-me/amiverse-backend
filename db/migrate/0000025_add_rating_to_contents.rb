class AddRatingToContents < ActiveRecord::Migration[8.1]
  RATING_EXPRESSION = "COALESCE(mod_rating, GREATEST(user_rating, COALESCE(auto_rating, 0)))".freeze

  def change
    %i[posts images videos drawings].each do |table|
      add_column table, :user_rating, :integer, null: false, limit: 1, default: 0
      add_column table, :auto_rating, :integer, null: true, limit: 1
      add_column table, :mod_rating, :integer, null: true, limit: 1
      add_column table, :rating, :virtual, type: :integer, as: RATING_EXPRESSION, stored: true
      add_index table, :rating
    end
  end
end
