# frozen_string_literal: true

class RenameDeliveredAtInNotifications < ActiveRecord::Migration[8.1]
  def change
    rename_column :notifications, :delivered_at, :whatsapp_delivered_at
  end
end
