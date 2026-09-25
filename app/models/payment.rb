# frozen_string_literal: true

class Payment < ApplicationRecord
  enum :status, { pending: 0, submitted: 1, approved: 2, rejected: 3 }, default: :pending

  belongs_to :account
  belongs_to :provider, optional: true

  has_one_attached :receipt

  before_validation :clear_rejection_reason, if: :submitted?

  validates :rejection_reason, presence: true, if: :rejected?

  validate :receipt_is_attached_when_submitted
  validate :receipt_has_allowed_type
  validate :receipt_is_within_size_limit

  def approve
    update(status: :approved, rejection_reason: nil)
  end

  def reject_with(reason)
    update(status: :rejected, rejection_reason: reason)
  end

  private

  def clear_rejection_reason
    self.rejection_reason = nil
  end

  def receipt_is_attached_when_submitted
    errors.add(:receipt, :required) if submitted? && !receipt.attached?
  end

  def receipt_has_allowed_type
    return unless receipt.attached?
    return if receipt.blob.content_type.in?([ "application/pdf", "image/jpeg", "image/png" ])

    errors.add(:receipt, :invalid_content_type)
  end

  def receipt_is_within_size_limit
    return unless receipt.attached?
    return unless receipt.blob.byte_size > 10.megabytes

    errors.add(:receipt, :too_large)
  end
end

# == Schema Information
#
# Table name: payments
#
#  id               :bigint           not null, primary key
#  rejection_reason :text
#  status           :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  provider_id      :bigint
#
# Indexes
#
#  index_payments_on_account_id   (account_id)
#  index_payments_on_provider_id  (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (provider_id => providers.id)
#
