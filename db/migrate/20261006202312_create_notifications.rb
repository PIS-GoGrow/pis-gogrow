# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :notification_configuration, null: false, foreign_key: true
      t.string :title
      t.string :description
      t.boolean :requires_action
      t.datetime :closed_at

      t.timestamps
    end
  end
end
