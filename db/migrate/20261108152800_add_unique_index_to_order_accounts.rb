# frozen_string_literal: true

class AddUniqueIndexToOrderAccounts < ActiveRecord::Migration[8.1]
  def change
    add_index :order_accounts, [ :account_id, :order_id ], unique: true, if_not_exists: true
  end
end
