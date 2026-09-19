# frozen_string_literal: true

class AddToppingsToMenus < ActiveRecord::Migration[8.1]
  def change
    add_column :menus, :fillings, :string, array: true, default: [], null: false
    add_column :menus, :sauces, :string, array: true, default: [], null: false
  end
end
