# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.date :month
      t.decimal :amount, precision: 10, scale: 2
      t.references :owner, polymorphic: true, null: false

      t.timestamps
    end
  end
end
