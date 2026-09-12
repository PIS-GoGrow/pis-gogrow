# frozen_string_literal: true

class AddRoleToSession < ActiveRecord::Migration[8.1]
  def change
    add_column :sessions, :role, :integer, null: false
  end
end
