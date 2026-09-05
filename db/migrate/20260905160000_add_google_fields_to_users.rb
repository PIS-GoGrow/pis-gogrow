# frozen_string_literal: true

class AddGoogleFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :google_uid, :string
    add_column :users, :avatar_url, :string
    add_index :users, :google_uid, unique: true
  end
end
