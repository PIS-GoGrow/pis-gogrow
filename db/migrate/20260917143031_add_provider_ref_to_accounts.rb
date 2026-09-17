# frozen_string_literal: true

class AddProviderRefToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_reference :accounts, :provider, null: false, foreign_key: true
  end
end
