# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :auditable, polymorphic: true
  belongs_to :user, optional: true
end

# == Schema Information
#
# Table name: audit_logs
#
#  id             :bigint           not null, primary key
#  auditable_type :string           not null
#  changeset      :jsonb            not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  auditable_id   :bigint           not null
#  user_id        :bigint
#
# Indexes
#
#  index_audit_logs_on_auditable  (auditable_type,auditable_id)
#  index_audit_logs_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
