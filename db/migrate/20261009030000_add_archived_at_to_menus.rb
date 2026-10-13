# frozen_string_literal: true

class AddArchivedAtToMenus < ActiveRecord::Migration[8.1]
  def change
    add_column :menus, :archived_at, :datetime
  end
end
