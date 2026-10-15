# frozen_string_literal: true

# Registra en AuditLog quién cambió los atributos sensibles y sus valores
# anterior y nuevo.
module Auditable
  extend ActiveSupport::Concern

  included do
    has_many :audit_logs, as: :auditable
  end

  class_methods do
    def audits(*attributes)
      after_update do
        changeset = saved_changes.slice(*attributes.map(&:to_s))
        audit_logs.create!(user: Current.user, changeset:) if changeset.any?
      end
    end
  end
end
