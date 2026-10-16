# frozen_string_literal: true

class RemoveDescriptionFromNotificationConfiguration < ActiveRecord::Migration[8.1]
  def change
    remove_column :notification_configurations, :description, :string
  end
end
