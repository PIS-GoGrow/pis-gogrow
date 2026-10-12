# frozen_string_literal: true

class AddVatRateToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :vat_rate, :decimal, precision: 3, scale: 2, default: 0, null: false
  end
end
