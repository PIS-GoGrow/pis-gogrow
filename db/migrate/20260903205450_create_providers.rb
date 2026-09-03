# frozen_string_literal: true

class CreateProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :providers do |t|
      t.string :email
      t.string :username
      t.time :order_deadline

      t.timestamps
    end
    add_index :providers, :email, unique: true
  end
end
