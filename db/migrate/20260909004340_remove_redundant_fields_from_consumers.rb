# frozen_string_literal: true

class RemoveRedundantFieldsFromConsumers < ActiveRecord::Migration[8.1]
  def change
    remove_column :consumers, :username, :string
    remove_column :consumers, :email, :string
  end
end
