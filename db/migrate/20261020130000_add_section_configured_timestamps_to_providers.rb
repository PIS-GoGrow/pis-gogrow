# frozen_string_literal: true

class AddSectionConfiguredTimestampsToProviders < ActiveRecord::Migration[8.1]
  def up
    add_column :providers, :payment_details_configured_at, :datetime
    add_column :providers, :order_deadline_configured_at, :datetime
    add_column :providers, :deliveries_configured_at, :datetime

    # Los proveedores que ya completaron el onboarding configuraron sus
    # secciones; marcarlas evita que la cuenta aparezca incompleta.
    execute <<~SQL.squish
      UPDATE providers
      SET payment_details_configured_at = onboarding_completed_at,
          order_deadline_configured_at = onboarding_completed_at,
          deliveries_configured_at = onboarding_completed_at
      WHERE onboarding_completed_at IS NOT NULL
    SQL
  end

  def down
    remove_column :providers, :payment_details_configured_at
    remove_column :providers, :order_deadline_configured_at
    remove_column :providers, :deliveries_configured_at
  end
end
