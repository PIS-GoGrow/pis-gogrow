# frozen_string_literal: true

class PaymentSerializer < ApplicationSerializer
  attributes :id, :status, :created_at

  typelize :string?
  attribute :receipt_url do |payment|
    next unless payment.receipt.attached?

    Rails.application.routes.url_helpers.receipt_payment_path(payment)
  end

  typelize :string?
  attribute :receipt_filename do |payment|
    payment.receipt.filename.to_s if payment.receipt.attached?
  end

  typelize :string?
  attribute :receipt_content_type do |payment|
    payment.receipt.content_type if payment.receipt.attached?
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
