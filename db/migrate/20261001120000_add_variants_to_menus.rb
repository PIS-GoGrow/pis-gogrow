# frozen_string_literal: true

class AddVariantsToMenus < ActiveRecord::Migration[8.1]
  def change
    add_reference :menus, :base_menu, foreign_key: { to_table: :menus }
    add_column :menus, :valid_from, :date
    add_column :menus, :valid_until, :date
  end
end
