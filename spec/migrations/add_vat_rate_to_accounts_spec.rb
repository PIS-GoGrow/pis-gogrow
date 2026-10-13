# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261012120000_add_vat_rate_to_accounts")

RSpec.describe AddVatRateToAccounts do
  it "deja las cuentas existentes y las inserciones del código anterior en cero aunque la activación esté configurada" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("COMPANY_ACCOUNT_VAT_ENABLED").and_return("true")
    connection = ActiveRecord::Base.connection
    original_path = connection.schema_search_path
    schema = "iva_migration_#{SecureRandom.hex(6)}"
    connection.create_schema(schema)
    connection.schema_search_path = schema
    connection.create_table(:accounts) do |table|
      table.decimal :amount, precision: 10, scale: 2
      table.string :owner_type
      table.date :month
    end
    connection.execute("INSERT INTO accounts (amount, owner_type, month) VALUES (800, 'Company', '2026-10-01'), (900, 'Company', '2026-11-01'), (500, 'Consumer', '2026-10-01')")
    original = connection.select_all("SELECT * FROM accounts ORDER BY id").to_a

    described_class.new.migrate(:up)

    migrated = connection.select_all("SELECT * FROM accounts ORDER BY id").to_a
    expect(migrated.map { it.except("vat_rate") }).to eq(original)
    expect(migrated.pluck("vat_rate")).to all(eq(0.to_d))
    connection.execute("INSERT INTO accounts (amount, owner_type, month) VALUES (1000, 'Company', '2026-10-01')")
    expect(connection.select_value("SELECT vat_rate FROM accounts ORDER BY id DESC LIMIT 1")).to eq(0.to_d)
  ensure
    connection.schema_search_path = original_path if original_path
    connection.drop_schema(schema, if_exists: true) if schema
  end
end
