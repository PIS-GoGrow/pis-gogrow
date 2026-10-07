# frozen_string_literal: true

class ModifyUserNotificationConfigurations < ActiveRecord::Migration[8.1]
  def change
    remove_index :user_notifications,
                 name: :index_user_notifications_on_user,
                 column: [ :user_type, :user_id ]
    remove_column :user_notifications, :user_type, :string

    add_index :user_notifications, :user_id
    add_foreign_key :user_notifications, :users

    rename_table :user_notifications, :user_notification_configurations
  end
end
