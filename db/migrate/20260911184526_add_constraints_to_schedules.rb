# frozen_string_literal: true

class AddConstraintsToSchedules < ActiveRecord::Migration[8.1]
  def change
    change_column_null :schedules, :date, false
    change_column_null :schedules, :amount, false

    add_index :schedules, [:menu_id, :date], unique: true #Protege nuestra regla de que un mismo plato no puede publicarse dos veces el mismo dia.

    add_check_constraint :schedules,
                         "amount >= 0", #El stock siempre debe existir y nunca puede ser negativo. Cero es valido como estado futuro de agotado.
                         name: "schedules_amount_non_negative"
  end
end