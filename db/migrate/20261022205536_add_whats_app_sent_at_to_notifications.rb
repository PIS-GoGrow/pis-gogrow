# frozen_string_literal: true

class AddWhatsAppSentAtToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :whatsapp_sent_at, :datetime
  end
end
