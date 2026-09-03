# frozen_string_literal: true

class CreateMenus < ActiveRecord::Migration[8.1]
  def change
    create_table :menus do |t|
      t.string :name
      t.string :description
      t.decimal :price, precision: 10, scale: 2
      t.references :provider, null: false, foreign_key: true

      t.timestamps
    end
  end
end
