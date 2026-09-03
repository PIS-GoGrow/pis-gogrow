# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.decimal :price, precision: 10, scale: 2
      t.decimal :discounted_price, precision: 10, scale: 2
      t.string :address
      t.integer :amount
      t.string :notes
      t.integer :status
      t.references :consumer, null: false, foreign_key: true
      t.references :schedule, null: false, foreign_key: true

      t.timestamps
    end
  end
end
