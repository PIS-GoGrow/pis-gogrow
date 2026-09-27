# frozen_string_literal: true

class CreateOrderBenefits < ActiveRecord::Migration[8.1]
  def change
    create_table :order_benefits do |t|
      t.references :benefit, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.decimal :amount_applied, precision: 10, scale: 2

      t.timestamps
    end
  end
end
