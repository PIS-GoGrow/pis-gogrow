# frozen_string_literal: true

class MakeStockOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :schedules, :amount, true
    change_column_null :menu_agendas, :amount, true
  end
end
