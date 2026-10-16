# frozen_string_literal: true

class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :auditable, polymorphic: true, null: false
      t.references :user, foreign_key: { on_delete: :nullify }
      t.jsonb :changeset, null: false, default: {}
      t.timestamps
    end
  end
end
