# frozen_string_literal: true

class CreateMenuOptionGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :menu_option_groups do |t|
      t.references :menu, null: false, foreign_key: true
      t.string :name, null: false
      t.string :options, array: true, default: []
      t.integer :limit, null: false, default: 1

      t.timestamps
    end
  end
end
