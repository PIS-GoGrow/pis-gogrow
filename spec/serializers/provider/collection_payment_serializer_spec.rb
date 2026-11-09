# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::CollectionPaymentSerializer do
  fixtures :users, :companies, :providers, :consumers, :accounts, :payments

  let(:account) { accounts(:one_tuviandita_current) }
  let(:provider) { providers(:tuviandita) }

  it "serializes payment attributes including rejection_reason" do
    payment = account.payments.build(
      provider:,
      status: :rejected,
      rejection_reason: "El pago es parcial",
      created_at: Time.zone.local(2026, 10, 2, 14, 30)
    )
    payment.receipt.attach(
      io: Rails.root.join("public/icon.png").open,
      filename: "parcial.png",
      content_type: "image/png"
    )
    payment.save!

    serialized = described_class.new(payment).to_h

    expect(serialized).to include(
      "id" => payment.id,
      "status" => "rejected",
      "rejection_reason" => "El pago es parcial",
      "date" => "02/10/26",
      "receipt_filename" => "parcial.png",
      "receipt_content_type" => "image/png"
    )
  end

  it "serializes rejection_reason as nil when payment is approved" do
    payment = account.payments.build(
      provider:,
      status: :approved,
      rejection_reason: nil,
      created_at: Time.zone.local(2026, 10, 5, 10, 0)
    )
    payment.receipt.attach(
      io: Rails.root.join("public/icon.png").open,
      filename: "aprobado.png",
      content_type: "image/png"
    )
    payment.save!

    serialized = described_class.new(payment).to_h

    expect(serialized["status"]).to eq("approved")
    expect(serialized["rejection_reason"]).to be_nil
  end
end
