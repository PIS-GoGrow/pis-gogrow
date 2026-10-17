# frozen_string_literal: true

class AddOnboardingCompletedAtToProviders < ActiveRecord::Migration[8.1]
  def up
    add_column :providers, :onboarding_completed_at, :datetime

    # Los proveedores que ya operan no pasan por el tour de alta.
    execute "UPDATE providers SET onboarding_completed_at = CURRENT_TIMESTAMP"
  end

  def down
    remove_column :providers, :onboarding_completed_at
  end
end
