# frozen_string_literal: true

class AddSelectedOptionsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :selected_options, :jsonb, null: false, default: []
  end
end
