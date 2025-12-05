class AddWebpushSettingsToNotificationSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :notification_settings, :wp_reaction, :boolean, null: false, default: true
    add_column :notification_settings, :wp_diffuse, :boolean, null: false, default: true
    add_column :notification_settings, :wp_reply, :boolean, null: false, default: true
    add_column :notification_settings, :wp_quote, :boolean, null: false, default: true
    add_column :notification_settings, :wp_follow, :boolean, null: false, default: true
    add_column :notification_settings, :wp_mention, :boolean, null: false, default: true
  end
end
