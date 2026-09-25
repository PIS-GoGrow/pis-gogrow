# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider payments", type: :request do
  self.fixture_table_names = []

  before { host! "localhost" }

  def create_provider(email)
    Provider.create!(user: User.create!(email:, name: "Provider", password: "password123456"))
  end

  def setup_submitted_payment
    company = Company.create!(name: "GoGrow", address: "18 de Julio 1006")
    consumer_user = User.create!(email: "review-consumer@gmail.com", name: "Consumer", password: "password123456")
    consumer = Consumer.create!(user: consumer_user, company:, address: "Ellauri 1234")
    provider = create_provider("review-provider@gmail.com")
    account = Account.create!(owner: consumer, provider:, month: Date.current, amount: 500)

    payment = account.payments.build(provider:, status: :submitted)
    payment.receipt.attach(io: StringIO.new("receipt"), filename: "receipt.png", content_type: "image/png")
    payment.save!

    [ provider.user, payment ]
  end

  it "approves a submitted payment" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)

    patch provider_payment_path(payment), params: { status: "approved" }

    expect(response).to redirect_to(provider_payments_path)
    expect(payment.reload).to be_approved
  end

  it "rejects a submitted payment with a reason" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)

    patch provider_payment_path(payment), params: { status: "rejected", rejection_reason: "Imagen borrosa" }

    expect(payment.reload).to be_rejected
    expect(payment.rejection_reason).to eq("Imagen borrosa")
  end

  it "does not reject without a reason" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)

    patch provider_payment_path(payment), params: { status: "rejected", rejection_reason: " " }

    expect(payment.reload).to be_submitted
  end

  it "does not let another provider review the payment" do
    _user, payment = setup_submitted_payment
    other = create_provider("other-provider@gmail.com")
    sign_in(other.user, role: :provider)

    patch provider_payment_path(payment), params: { status: "approved" }

    expect(response).to have_http_status(:not_found)
    expect(payment.reload).to be_submitted
  end

  it "lets the provider open the receipt of their payment" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)

    get receipt_provider_payment_path(payment)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/png")
  end

  it "does not let another provider open the receipt" do
    _user, payment = setup_submitted_payment
    other = create_provider("other-provider@gmail.com")
    sign_in(other.user, role: :provider)

    get receipt_provider_payment_path(payment)

    expect(response).to have_http_status(:not_found)
  end
end
