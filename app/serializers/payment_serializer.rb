# frozen_string_literal: true

class PaymentSerializer < ApplicationSerializer
  attributes :id, :status, :created_at

  typelize :string?
  attribute :receipt_url do |payment|
    next unless payment.receipt.attached?

    # Se entrega una URL firmada por Active Storage; el archivo no se duplica en el frontend.
    Rails.application.routes.url_helpers.rails_blob_path(payment.receipt, disposition: "inline", only_path: true)
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
#  id         :bigint           not null, primary key
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_payments_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
