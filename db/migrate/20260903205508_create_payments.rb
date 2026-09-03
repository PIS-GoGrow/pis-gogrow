# frozen_string_literal: true

class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.integer :status
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
