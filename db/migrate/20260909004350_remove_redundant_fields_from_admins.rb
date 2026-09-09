# frozen_string_literal: true

class RemoveRedundantFieldsFromAdmins < ActiveRecord::Migration[8.1]
  def change
    remove_column :admins, :username, :string
    remove_column :admins, :email, :string
  end
end
