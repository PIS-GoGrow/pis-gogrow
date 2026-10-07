# frozen_string_literal: true

class AddRolesToNotificationConfigurations < ActiveRecord::Migration[8.1]
  def change
    add_column :notification_configurations, :roles, :string, array: true, default: []
  end
end
