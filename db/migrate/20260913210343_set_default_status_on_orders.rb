# frozen_string_literal: true

class SetDefaultStatusOnOrders < ActiveRecord::Migration[8.1]
  def change
    change_column_default :orders, :status, from: nil, to: 0
    change_column_null :orders, :status, false, 0
  end
end
