# frozen_string_literal: true

class RemoveToppingsFromMenus < ActiveRecord::Migration[8.1]
  def change
    remove_column :menus, :fillings, :string, array: true, default: []
    remove_column :menus, :sauces, :string, array: true, default: []
  end
end
