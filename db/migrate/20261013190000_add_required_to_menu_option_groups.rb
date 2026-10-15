# frozen_string_literal: true

class AddRequiredToMenuOptionGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :menu_option_groups, :required, :boolean, default: false, null: false
  end
end
