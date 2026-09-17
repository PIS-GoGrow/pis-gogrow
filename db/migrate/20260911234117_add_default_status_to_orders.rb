# frozen_string_literal: true

class AddDefaultStatusToOrders < ActiveRecord::Migration[8.1]
  def change
    change_column_default :orders, :status, from: nil, to: 0
    up_only { Order.where(status: nil).update_all(status: 0) }
    change_column_null :orders, :status, false
  end
end
