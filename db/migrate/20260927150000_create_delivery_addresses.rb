# frozen_string_literal: true

class CreateDeliveryAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :delivery_addresses do |t|
      t.references :consumer, null: false, foreign_key: true
      t.string :name, null: false
      t.string :street, null: false
      t.string :apartment

      t.timestamps
    end
  end
end
