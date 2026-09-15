# frozen_string_literal: true

class AddRolesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :roles, :string, array: true, default: [], null: false
  end
end
