class AddDeviceInfoToWebpushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :webpush_subscriptions, :name, :string, null: false, default: ""
    add_column :webpush_subscriptions, :meta, :json, null: false, default: {}
    add_column :webpush_subscriptions, :status, :integer, limit: 1, null: false, default: 0
  end
end
