# frozen_string_literal: true

class AddTwilioSidToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :twilio_sid, :string, null: true
    add_index :notifications, :twilio_sid
  end
end
