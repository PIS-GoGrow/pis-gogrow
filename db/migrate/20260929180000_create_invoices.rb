# frozen_string_literal: true

class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :account, null: false, foreign_key: true
      t.date :issued_on, null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :invoices, :account_id, unique: true, where: "status IN (0, 1)", name: "index_invoices_on_account_id_active"
  end
end
