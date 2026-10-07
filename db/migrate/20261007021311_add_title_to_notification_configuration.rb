# frozen_string_literal: true

class AddTitleToNotificationConfiguration < ActiveRecord::Migration[8.1]
  def change
    add_column :notification_configurations, :title, :string
  end
end
