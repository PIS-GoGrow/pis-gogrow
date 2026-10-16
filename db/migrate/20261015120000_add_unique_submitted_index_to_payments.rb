# frozen_string_literal: true

# Una cuenta puede tener varios comprobantes a lo largo del tiempo (pagos
# parciales, reenvíos tras un rechazo), pero solo uno en revisión (status 1 =
# submitted) a la vez. El índice parcial es la garantía real: dos pestañas
# enviando al mismo tiempo pasan la validación del modelo, pero no el índice.
class AddUniqueSubmittedIndexToPayments < ActiveRecord::Migration[8.1]
  INDEX_NAME = "index_payments_on_account_id_submitted"

  def up
    # Antes se podían subir dos desde pestañas distintas. De las cuentas que
    # ya tengan más de uno en revisión se conserva el más viejo y los demás
    # se rechazan con un motivo, para que el empleado los pueda reenviar.
    execute <<~SQL.squish
      UPDATE payments
      SET status = 3,
          rejection_reason = 'Había otro comprobante en revisión para esta cuenta. Volvé a enviarlo cuando se resuelva.',
          updated_at = NOW()
      WHERE status = 1
        AND id NOT IN (SELECT MIN(id) FROM payments WHERE status = 1 GROUP BY account_id)
    SQL

    add_index :payments, :account_id, unique: true, where: "status = 1", name: INDEX_NAME
  end

  def down
    remove_index :payments, name: INDEX_NAME
  end
end
