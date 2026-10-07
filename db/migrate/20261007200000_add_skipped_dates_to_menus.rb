# frozen_string_literal: true

class AddSkippedDatesToMenus < ActiveRecord::Migration[8.1]
  def change
    add_column :menus, :skipped_dates, :date, array: true, default: [], null: false
  end
end
