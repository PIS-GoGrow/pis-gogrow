# frozen_string_literal: true

class AddColsToNotification < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :role, :string, null: false
    add_column :notifications, :event, :string, null: false
    add_reference :notifications, :notifiable, polymorphic: true, null: false

    change_column_null :notifications, :requires_action, false

    add_index :notifications, [ :notifiable_type, :notifiable_id, :event ],
          unique: true, where: "closed_at IS NULL AND requires_action = true",
          name: "index_notifications_one_active_per_event"
  end
end
