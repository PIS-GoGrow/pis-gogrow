# frozen_string_literal: true

class CreateProviderClosures < ActiveRecord::Migration[8.1]
  def change
    create_table :provider_closures do |t|
      t.references :provider, null: false, foreign_key: true
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.string :reason, null: false

      t.timestamps

      t.index [ :provider_id, :starts_on ]
      t.check_constraint "ends_on >= starts_on", name: "provider_closures_ends_on_after_starts_on"
    end
  end
end
