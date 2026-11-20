# frozen_string_literal: true

class RemoveRolesFromUser < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :roles, :string
  end
end
