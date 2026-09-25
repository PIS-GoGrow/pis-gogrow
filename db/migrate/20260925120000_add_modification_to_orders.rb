# frozen_string_literal: true

class AddModificationToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :modified_at, :datetime
    add_reference :orders, :modified_by, foreign_key: { to_table: :users }
  end
end
