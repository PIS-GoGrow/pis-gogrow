# frozen_string_literal: true

class RemoveRedundantFieldsFromProviders < ActiveRecord::Migration[8.1]
  def change
    remove_column :providers, :username, :string
    remove_column :providers, :email, :string
  end
end
