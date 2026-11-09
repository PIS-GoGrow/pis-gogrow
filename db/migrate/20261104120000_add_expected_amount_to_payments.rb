# frozen_string_literal: true

class AddExpectedAmountToPayments < ActiveRecord::Migration[8.1]
  def up
    add_column :payments, :expected_amount, :decimal, precision: 10, scale: 2

    # No hay forma de saber cuánto debía la cuenta cuando se envió cada
    # comprobante: se toma lo que debe hoy, que es lo que se venía mostrando.
    execute <<~SQL.squish
      UPDATE payments
      SET expected_amount = COALESCE(accounts.amount, 0) + ROUND(COALESCE(accounts.amount, 0) * accounts.vat_rate, 2)
      FROM accounts
      WHERE accounts.id = payments.account_id
    SQL
  end

  def down
    remove_column :payments, :expected_amount
  end
end
