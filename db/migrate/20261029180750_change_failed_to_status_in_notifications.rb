# frozen_string_literal: true

class ChangeFailedToStatusInNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :whatsapp_send_status, :integer
    remove_column :notifications, :failed, :boolean
    rename_column :notifications, :whatsapp_sent_at, :whatsapp_last_sent_at
    rename_column :notifications, :send_attempts, :whatsapp_send_attempts
  end
end
