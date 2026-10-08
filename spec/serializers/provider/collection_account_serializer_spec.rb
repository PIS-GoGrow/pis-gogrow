# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::CollectionAccountSerializer do
  fixtures :users, :companies, :providers, :consumers, :accounts, :payments

  let(:account) { accounts(:one_tuviandita_current) }
  let(:provider) { providers(:tuviandita) }

  def create_payment(account, status:, created_at: Time.current, rejection_reason: nil)
    payment = account.payments.build(provider: account.provider, status:, created_at:, rejection_reason:)
    payment.receipt.attach(
      io: Rails.root.join("public/icon.png").open,
      filename: "receipt.png",
      content_type: "image/png"
    )
    payment.save!
    payment
  end

  it "prioritizes the oldest submitted payment for payment_id and receipt_url when multiple payments exist" do
    account.payments.destroy_all
    older_submitted = create_payment(account, status: :submitted, created_at: 2.days.ago)
    create_payment(account, status: :submitted, created_at: 1.day.ago)

    row = ProviderCollectionSummary::AccountRow.new(account:, meals: 3)
    serialized = described_class.new(row).to_h

    expect(serialized["payment_id"]).to eq(older_submitted.id)
    expect(serialized["status"]).to eq("submitted")
    expect(serialized["receipt_url"]).to eq(Rails.application.routes.url_helpers.receipt_provider_payment_path(older_submitted))
  end

  it "falls back to the last payment when no submitted payment exists" do
    account.payments.destroy_all
    rejected = create_payment(account, status: :rejected, rejection_reason: "El pago es parcial", created_at: 1.day.ago)

    row = ProviderCollectionSummary::AccountRow.new(account:, meals: 3)
    serialized = described_class.new(row).to_h

    expect(serialized["payment_id"]).to eq(rejected.id)
    expect(serialized["status"]).to eq("rejected")
    expect(serialized["receipt_url"]).to eq(Rails.application.routes.url_helpers.receipt_provider_payment_path(rejected))
  end

  it "returns nil payment_id and receipt_url when account has no payments" do
    account.payments.destroy_all

    row = ProviderCollectionSummary::AccountRow.new(account:, meals: 0)
    serialized = described_class.new(row).to_h

    expect(serialized["payment_id"]).to be_nil
    expect(serialized["receipt_url"]).to be_nil
    expect(serialized["status"]).to eq("pending")
  end
end
