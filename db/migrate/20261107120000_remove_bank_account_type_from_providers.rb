# frozen_string_literal: true

class RemoveBankAccountTypeFromProviders < ActiveRecord::Migration[8.1]
  def change
    remove_column :providers, :bank_account_type, :integer
  end
end
