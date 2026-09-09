# frozen_string_literal: true

class ChangeScheduleIdNullOnOrders < ActiveRecord::Migration[8.1]
  def change
    change_column_null :orders, :schedule_id, true
  end
end
