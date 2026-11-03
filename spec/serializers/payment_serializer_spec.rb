# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaymentSerializer do
  fixtures :users, :companies, :providers, :consumers, :accounts

  let(:account) { accounts(:one_tuviandita_current) }
  let(:provider) { providers(:tuviandita) }

  it "serializes the size in bytes of the attached receipt" do
    payment = account.payments.build(provider:, status: :submitted)
    payment.receipt.attach(
      io: Rails.root.join("public/icon.png").open,
      filename: "icon.png",
      content_type: "image/png"
    )
    payment.save!

    serialized = described_class.new(payment).to_h

    expect(serialized).to include(
      "receipt_filename" => "icon.png",
      "receipt_byte_size" => Rails.root.join("public/icon.png").size
    )
  end

  it "serializes no size when the payment has no receipt" do
    payment = account.payments.create!(provider:, status: :pending)

    expect(described_class.new(payment).to_h["receipt_byte_size"]).to be_nil
  end
end
