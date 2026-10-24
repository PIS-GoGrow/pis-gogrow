# frozen_string_literal: true

class CreateOrderEvents < ActiveRecord::Migration[8.1]
  def change
    # Sin foreign key a orders: el registro tiene que sobrevivir aunque se
    # borre el pedido, por ejemplo al eliminar la cuenta del empleado.
    create_table :order_events do |t|
      t.bigint :order_id, null: false, index: true
      t.references :company, null: false, foreign_key: true, index: false
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :actor_name
      t.integer :role
      t.integer :action, null: false
      t.jsonb :changeset, null: false, default: {}

      t.datetime :created_at, null: false
    end

    add_index :order_events, [ :company_id, :created_at ]
  end
end
