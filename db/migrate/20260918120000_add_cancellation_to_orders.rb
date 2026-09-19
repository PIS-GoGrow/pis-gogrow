# frozen_string_literal: true

class AddCancellationToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :cancelled_at, :datetime
    add_column :orders, :status_before_cancellation, :integer
    add_reference :orders, :cancelled_by, foreign_key: { to_table: :users }
  end
end
