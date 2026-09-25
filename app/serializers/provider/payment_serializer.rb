# frozen_string_literal: true

class Provider::PaymentSerializer < ApplicationSerializer
  typelize_from Payment

  attributes :id, :status

  typelize :number
  attribute :amount do |payment|
    payment.account.amount.to_f
  end

  typelize :string
  attribute :date do |payment|
    payment.created_at.strftime("%d/%m/%y")
  end

  # El dueño de la cuenta es un Consumer (empleado) o una Company.
  typelize :string
  attribute :employee_name do |payment|
    owner = payment.account.owner
    owner.is_a?(Consumer) ? owner.user.name : owner.name
  end

  typelize :string, nullable: true
  attribute :receipt_url do |payment|
    next unless payment.receipt.attached?

    Rails.application.routes.url_helpers.receipt_provider_payment_path(payment)
  end

  typelize :string, nullable: true
  attribute :receipt_content_type do |payment|
    payment.receipt.content_type if payment.receipt.attached?
  end
end
