# frozen_string_literal: true

class AddConfigurableToNotificationConfiguration < ActiveRecord::Migration[8.1]
  def change
    add_column :notification_configurations, :configurable, :boolean
  end
end
