# frozen_string_literal: true

class AddModificationToMenus < ActiveRecord::Migration[8.1]
  def change
    add_column :menus, :modified_at, :datetime
    add_reference :menus, :modified_by, foreign_key: { to_table: :users }
    add_column :menus, :modified_values, :jsonb
  end
end
