# frozen_string_literal: true

class CreateNotificationConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_configurations do |t|
      t.string :description

      t.timestamps
    end
  end
end
