# frozen_string_literal: true

class AddFieldsToNotification < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :delivered_at, :datetime
    add_column :notifications, :title_data, :json
    add_column :notifications, :description_data, :json
    add_column :notifications, :send_attempts, :integer, default: 0
  end
end
