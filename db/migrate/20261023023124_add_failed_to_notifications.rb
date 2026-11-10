# frozen_string_literal: true

class AddFailedToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :failed, :boolean
  end
end
