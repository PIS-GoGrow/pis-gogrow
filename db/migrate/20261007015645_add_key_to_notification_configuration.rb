# frozen_string_literal: true

class AddKeyToNotificationConfiguration < ActiveRecord::Migration[8.1]
  def change
    add_column :notification_configurations, :key, :string, null: false
    add_index :notification_configurations, :key, unique: true
  end
end
