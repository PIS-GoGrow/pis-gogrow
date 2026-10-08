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
    account = Account.create!(owner: consumer, provider:, month: Date.current.prev_month, amount: 500)

    payment = account.payments.build(provider:, status: :submitted)
    payment.receipt.attach(io: StringIO.new("receipt"), filename: "receipt.png", content_type: "image/png")
    payment.save!

    [ provider.user, payment ]
  end

  it "approves a submitted payment" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)

    patch provider_payment_path(payment), params: { status: "approved" }

    expect(response).to redirect_to(provider_collections_path)
    expect(payment.reload).to be_approved
  end

  it "does not approve a payment of the current month" do
    user, payment = setup_submitted_payment
    payment.account.update!(month: Date.current.beginning_of_month)
    sign_in(user, role: :provider)

    patch provider_payment_path(payment), params: { status: "approved" }

    expect(response).to redirect_to(provider_collections_path)
    follow_redirect!
    expect(inertia).to have_flash(alert: I18n.t("validations.payment_current_account"))
    expect(payment.reload).to be_submitted
  end

  # Solo se bloquea aprobar: rechazar un comprobante del mes en curso sigue permitido.
  it "still rejects a payment of the current month" do
    user, payment = setup_submitted_payment
    payment.account.update!(month: Date.current.beginning_of_month)
    sign_in(user, role: :provider)

    patch provider_payment_path(payment), params: { status: "rejected", rejection_reason: "Imagen borrosa" }

    expect(payment.reload).to be_rejected
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

  it "does not review a payment that was already reviewed" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)
    patch provider_payment_path(payment), params: { status: "approved" }

    patch provider_payment_path(payment), params: { status: "rejected", rejection_reason: " otra vez" }

    expect(response).to redirect_to(provider_collections_path)
    expect(payment.reload).to be_approved
    expect(payment.rejection_reason).to be_nil
  end

  it "does not accept a status the provider does not offer" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)

    patch provider_payment_path(payment), params: { status: "cancelled" }

    expect(response).to have_http_status(:unprocessable_entity)
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

  it "redirects a consumer trying to review a payment" do
    _user, payment = setup_submitted_payment
    consumer_user = User.create!(email: "unauth-consumer@gmail.com", name: "Consumer", password: "password123456")
    Consumer.create!(user: consumer_user, company: Company.first, address: "Ellauri 123")
    sign_in(consumer_user, role: :consumer)

    patch provider_payment_path(payment), params: { status: "approved" }

    expect(response).to redirect_to(root_path)
    expect(payment.reload).to be_submitted
  end

  it "redirects an admin trying to review a payment" do
    _user, payment = setup_submitted_payment
    admin_user = User.create!(email: "unauth-admin@gmail.com", name: "Admin", password: "password123456")
    Admin.create!(user: admin_user, company: Company.first)
    sign_in(admin_user, role: :admin)

    patch provider_payment_path(payment), params: { status: "approved" }

    expect(response).to redirect_to(root_path)
    expect(payment.reload).to be_submitted
  end

  it "handles partial payment rejection without notice and keeps account submitted if another payment is pending" do
    user, first_payment = setup_submitted_payment
    account = first_payment.account
    second_payment = account.payments.build(provider: first_payment.provider, status: :submitted)
    second_payment.receipt.attach(io: StringIO.new("receipt2"), filename: "receipt2.png", content_type: "image/png")
    second_payment.save!

    sign_in(user, role: :provider)

    patch provider_payment_path(first_payment), params: { status: "rejected", rejection_reason: "El pago es parcial" }

    expect(response).to redirect_to(provider_collections_path)
    expect(response).to have_http_status(:see_other)
    expect(flash[:notice]).to be_nil
    expect(first_payment.reload.rejection_reason).to eq("El pago es parcial")
    expect(account.reload.collection_status).to eq("submitted")
    expect(account.payment_pending_review).to eq(second_payment)

    patch provider_payment_path(second_payment), params: { status: "approved" }

    expect(response).to redirect_to(provider_collections_path)
    expect(second_payment.reload).to be_approved
    expect(account.reload.payment_pending_review).to be_nil
    expect(account.collection_status).to eq("approved")
  end
end
