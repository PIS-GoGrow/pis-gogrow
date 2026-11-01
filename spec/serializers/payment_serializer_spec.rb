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
#  index_payments_on_account_id            (account_id)
#  index_payments_on_account_id_submitted  (account_id) UNIQUE WHERE (status = 1)
#  index_payments_on_provider_id           (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (provider_id => providers.id)
#
