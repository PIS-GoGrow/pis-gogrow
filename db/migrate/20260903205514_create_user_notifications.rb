# frozen_string_literal: true

class CreateUserNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :user_notifications do |t|
      t.references :notification_configuration, null: false, foreign_key: true
      t.references :user, polymorphic: true, null: false

      t.timestamps
    end
  end
end
