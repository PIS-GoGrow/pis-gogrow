# frozen_string_literal: true

class AddProviderToPayments < ActiveRecord::Migration[8.1]
  def up
    add_reference :payments, :provider, foreign_key: true
    execute "UPDATE payments SET status = 0 WHERE status IS NULL"
    change_column_default :payments, :status, from: nil, to: 0
    change_column_null :payments, :status, false
  end

  def down
    change_column_null :payments, :status, true
    change_column_default :payments, :status, from: 0, to: nil
    remove_reference :payments, :provider, foreign_key: true
  end
end
