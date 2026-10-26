# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider payments", type: :request do
  self.fixture_table_names = []

  before { host! "localhost" }

  def create_provider(email)
    Provider.create!(user: User.create!(email:, name: "Provider", password: "password123456"), onboarding_completed_at: Time.current)
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

  it "lets HR know when the payment of the company is approved" do
    company = Company.create!(name: "GoGrow", address: "18 de Julio 1006")
    admin_user = User.create!(email: "review-admin@gmail.com", name: "RRHH", password: "password123456")
    Admin.create!(user: admin_user, company:)
    provider = create_provider("review-provider@gmail.com")
    account = Account.create!(owner: company, provider:, month: Date.current.prev_month, amount: 500)
    payment = account.payments.build(provider:, status: :submitted)
    payment.receipt.attach(io: StringIO.new("receipt"), filename: "receipt.png", content_type: "image/png")
    payment.save!
    sign_in(provider.user, role: :provider)

    patch provider_payment_path(payment), params: { status: "approved" }

    expect(admin_user.notifications.active.sole).to have_attributes(event: "company_payment_approved", notifiable: account)
  end

  it "approves the pending invoice when a company payment is approved" do
    company = Company.create!(name: "GoGrow", address: "18 de Julio 1006")
    provider = create_provider("invoice-review-provider@gmail.com")
    account = Account.create!(
      owner: company,
      provider:,
      month: Date.current.prev_month,
      amount: 500
    )

    invoice = account.invoices.build(
      issued_on: Date.current,
      total_amount: 500
    )
    invoice.file.attach(
      io: StringIO.new("%PDF-1.4"),
      filename: "factura.pdf",
      content_type: "application/pdf"
    )
    invoice.save!

    payment = account.payments.build(provider:, status: :submitted)
    payment.receipt.attach(
      io: StringIO.new("receipt"),
      filename: "receipt.png",
      content_type: "image/png"
    )
    payment.save!

    sign_in(provider.user, role: :provider)

    patch provider_payment_path(payment), params: { status: "approved" }

    expect(payment.reload).to be_approved
    expect(invoice.reload).to be_approved
  end

  it "keeps the invoice pending when the company payment is rejected" do
    company = Company.create!(name: "GoGrow", address: "18 de Julio 1006")
    provider = create_provider("invoice-reject-provider@gmail.com")
    account = Account.create!(
      owner: company,
      provider:,
      month: Date.current.prev_month,
      amount: 500
    )

    invoice = account.invoices.build(
      issued_on: Date.current,
      total_amount: 500
    )
    invoice.file.attach(
      io: StringIO.new("%PDF-1.4"),
      filename: "factura.pdf",
      content_type: "application/pdf"
    )
    invoice.save!

    payment = account.payments.build(provider:, status: :submitted)
    payment.receipt.attach(
      io: StringIO.new("receipt"),
      filename: "receipt.png",
      content_type: "image/png"
    )
    payment.save!

    sign_in(provider.user, role: :provider)

    patch provider_payment_path(payment),
          params: {
            status: "rejected",
            rejection_reason: "incorrect_receipt"
          }

    expect(payment.reload).to be_rejected
    expect(invoice.reload).to be_pending
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

    patch provider_payment_path(payment),
          params: { status: "rejected", rejection_reason: "incorrect_receipt" }

    expect(payment.reload).to be_rejected
  end

  it "rejects a submitted payment with a reason" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)

    patch provider_payment_path(payment),
          params: { status: "rejected", rejection_reason: "incorrect_receipt" }

    expect(payment.reload).to be_rejected
    expect(payment.rejection_reason).to eq("El comprobante no corresponde")
  end

  it "does not reject without a reason" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)

    patch provider_payment_path(payment), params: { status: "rejected", rejection_reason: " " }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(payment.reload).to be_submitted
  end

  it "does not accept a rejection reason outside the offered options" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)

    patch provider_payment_path(payment),
          params: { status: "rejected", rejection_reason: "<script>alert(1)</script>" }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(payment.reload).to be_submitted
    expect(payment.rejection_reason).to be_nil
  end

  it "stores a trimmed custom rejection reason" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)

    patch provider_payment_path(payment),
          params: {
            status: "rejected",
            rejection_reason: "other",
            rejection_details: "  El importe no coincide  "
          }

    expect(response).to redirect_to(provider_collections_path)
    expect(payment.reload).to be_rejected
    expect(payment.rejection_reason).to eq("El importe no coincide")
  end

  it "does not accept an empty custom rejection reason" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)

    patch provider_payment_path(payment),
          params: { status: "rejected", rejection_reason: "other", rejection_details: "   " }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(payment.reload).to be_submitted
    expect(payment.rejection_reason).to be_nil
  end

  it "does not accept an excessively long custom rejection reason" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)

    patch provider_payment_path(payment),
          params: { status: "rejected", rejection_reason: "other", rejection_details: "a" * 501 }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(payment.reload).to be_submitted
    expect(payment.rejection_reason).to be_nil
  end

  it "does not review a payment that was already reviewed" do
    user, payment = setup_submitted_payment
    sign_in(user, role: :provider)
    patch provider_payment_path(payment), params: { status: "approved" }

    patch provider_payment_path(payment), params: { status: "rejected", rejection_reason: "other" }

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
    expect(inertia).to render_component("errors/not_found")
  end

  it "keeps a rejected partial payment receipt accessible only to its provider" do
    user, payment = setup_submitted_payment
    payment.update!(status: :rejected, rejection_reason: "El pago es parcial")
    sign_in(user, role: :provider)

    get receipt_provider_payment_path(payment)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/png")
    expect(payment.reload).to be_rejected

    other = create_provider("other-receipt-provider@gmail.com")
    sign_in(other.user, role: :provider)
    get receipt_provider_payment_path(payment)

    expect(response).to have_http_status(:not_found)
    expect(payment.reload).to be_rejected
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

  it "handles partial payment rejection without notice and leaves the account rejected until a new receipt arrives" do
    user, payment = setup_submitted_payment
    account = payment.account

    sign_in(user, role: :provider)

    patch provider_payment_path(payment),
          params: { status: "rejected", rejection_reason: "partial_payment" }

    expect(response).to redirect_to(provider_collections_path)
    expect(response).to have_http_status(:see_other)
    expect(flash[:notice]).to be_nil
    expect(payment.reload.rejection_reason).to eq("El pago es parcial")
    expect(account.reload.payment_pending_review).to be_nil
    expect(account.collection_status).to eq("rejected")
  end

  describe "manual debt reminders closure on review" do
    before do
      Notification::Configuration.find_or_create_by!(key: "provider_payment_reminders") do |c|
        c.roles = [ "consumer" ]
      end
    end

    def create_reminder(account)
      Notifier.call(
        event_key: "debt_payment_reminder",
        user: account.owner.user,
        notifiable: account,
        description_data: {
          amount: "$500",
          provider: account.provider.user.name,
          period: "octubre de 2026"
        }
      )
    end

    it "closes the active manual debt reminder when approved" do
      user, payment = setup_submitted_payment
      reminder = create_reminder(payment.account)
      sign_in(user, role: :provider)

      patch provider_payment_path(payment), params: { status: "approved" }

      expect(response).to redirect_to(provider_collections_path)
      expect(payment.reload).to be_approved
      expect(reminder.reload.closed_at).to be_present
    end

    it "leaves the manual debt reminder active when rejected" do
      user, payment = setup_submitted_payment
      reminder = create_reminder(payment.account)
      sign_in(user, role: :provider)

      patch provider_payment_path(payment),
            params: { status: "rejected", rejection_reason: "incorrect_receipt" }

      expect(response).to redirect_to(provider_collections_path)
      expect(payment.reload).to be_rejected
      expect(reminder.reload.closed_at).to be_nil
    end

    it "does not close the reminder if approval fails due to invalid parameters (bypass de interfaz: 422)" do
      user, payment = setup_submitted_payment
      reminder = create_reminder(payment.account)
      sign_in(user, role: :provider)

      patch provider_payment_path(payment), params: { status: "invalid_status" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(payment.reload).to be_submitted
      expect(reminder.reload.closed_at).to be_nil
    end

    it "does not close the reminder if approving a current month payment (business rule redirect)" do
      user, payment = setup_submitted_payment
      payment.account.update!(month: Date.current.beginning_of_month)
      reminder = create_reminder(payment.account)
      sign_in(user, role: :provider)

      patch provider_payment_path(payment), params: { status: "approved" }

      expect(response).to redirect_to(provider_collections_path)
      expect(payment.reload).to be_submitted
      expect(reminder.reload.closed_at).to be_nil
    end

    it "does not close the reminder if an unauthorized role attempts to approve" do
      _user, payment = setup_submitted_payment
      reminder = create_reminder(payment.account)
      consumer_user = payment.account.owner.user
      sign_in(consumer_user, role: :consumer)

      patch provider_payment_path(payment), params: { status: "approved" }

      expect(response).to redirect_to(root_path)
      expect(payment.reload).to be_submitted
      expect(reminder.reload.closed_at).to be_nil
    end

    it "only closes reminders for the paid account, not reminders from another account" do
      user, payment = setup_submitted_payment
      reminder1 = create_reminder(payment.account)

      other_account = Account.create!(
        owner: payment.account.owner,
        provider: payment.provider,
        month: 2.months.ago.to_date,
        amount: 300
      )
      reminder2 = create_reminder(other_account)

      sign_in(user, role: :provider)
      patch provider_payment_path(payment), params: { status: "approved" }

      expect(reminder1.reload.closed_at).to be_present
      expect(reminder2.reload.closed_at).to be_nil
    end
  end
end
