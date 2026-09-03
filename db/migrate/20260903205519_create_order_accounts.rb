# frozen_string_literal: true

class CreateOrderAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :order_accounts do |t|
      t.references :account, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true

      t.timestamps
    end
  end
end
