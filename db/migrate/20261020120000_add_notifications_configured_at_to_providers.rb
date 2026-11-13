# frozen_string_literal: true

class AddNotificationsConfiguredAtToProviders < ActiveRecord::Migration[8.1]
  def up
    add_column :providers, :notifications_configured_at, :datetime

    # Los proveedores que ya completaron el onboarding eligieron sus
    # notificaciones; marcarlas evita que la cuenta aparezca incompleta.
    execute <<~SQL.squish
      UPDATE providers
      SET notifications_configured_at = onboarding_completed_at
      WHERE onboarding_completed_at IS NOT NULL
    SQL
  end

  def down
    remove_column :providers, :notifications_configured_at
  end
end
