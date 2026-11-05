# frozen_string_literal: true

class AdaptProviderPaymentDetailsToFigma < ActiveRecord::Migration[8.1]
  def up
    rename_column :providers, :bank_account_number, :bank_account_details
    change_column :providers, :bank_account_details, :text
    rename_column :providers, :bank_account_holder, :beneficiary
  end

  def down
    rename_column :providers, :beneficiary, :bank_account_holder
    change_column :providers, :bank_account_details, :string
    rename_column :providers, :bank_account_details, :bank_account_number
  end
end
