# frozen_string_literal: true

class RemoveAmountFromSchedulesAndMenuAgendas < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :schedules, name: "schedules_amount_non_negative", if_exists: true
    remove_column :schedules, :amount, :integer
    remove_column :menu_agendas, :amount, :integer
  end
end
