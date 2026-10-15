# frozen_string_literal: true

class AddPaymentDetailsToProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :providers, :bank_name, :string
    add_column :providers, :bank_account_type, :integer
    add_column :providers, :bank_account_number, :string
    add_column :providers, :bank_account_holder, :string
    add_column :providers, :tax_id, :string
  end
end
