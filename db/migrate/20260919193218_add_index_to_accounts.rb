# frozen_string_literal: true

class AddIndexToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_index :accounts, [ :owner_type, :owner_id, :provider_id, :month ], unique: true
  end
end
