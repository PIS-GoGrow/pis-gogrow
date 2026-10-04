# frozen_string_literal: true

require "rails_helper"

raise "Payment request specs must run in RAILS_ENV=test" unless Rails.env.test?

RSpec.describe "Payments", type: :request do
  self.fixture_table_names = []

  before { host! "localhost" }

  def setup_payment_account
    company = Company.create!(name: "GoGrow", address: "18 de Julio 1006")
    consumer_user = User.create!(email: "payment-consumer@gmail.com", name: "Consumer", password: "password123456")
    consumer = Consumer.create!(user: consumer_user, company:, address: "Ellauri 1234")
    provider_user = User.create!(email: "payment-provider@gmail.com", name: "Provider", password: "password123456")
    provider = Provider.create!(user: provider_user)
    account = Account.create!(owner: consumer, provider:, month: Date.current.prev_month, amount: 500)

    [ consumer_user, account, provider ]
  end

  def receipt_upload(filename: "receipt.png")
    Rack::Test::UploadedFile.new(
      Rails.root.join("public/icon.png"),
      "image/png",
      original_filename: filename
    )
  end

  def account_page_headers
    { "HTTP_REFERER" => accounts_url }
  end

  def submitted_payment(account:, provider:)
    payment = account.payments.build(provider:, status: :submitted)
    payment.receipt.attach(
      io: StringIO.new("receipt"),
      filename: "receipt.png",
      content_type: "image/png"
    )
    payment.save!
    payment
  end

  it "creates a submitted payment with a receipt for an account without payments" do
    user, account, provider = setup_payment_account
    sign_in(user, role: :consumer)

    expect {
      post payments_path, params: {
        payment: { account_id: account.id, receipt: receipt_upload }
      }, headers: account_page_headers
    }.to change(Payment, :count).by(1)

    payment = account.payments.reload.sole
    expect(response).to redirect_to(accounts_path)
    expect(payment).to be_submitted
    expect(payment.account).to eq(account)
    expect(payment.account.owner).to eq(user.consumer)
    expect(payment.provider).to eq(provider)
    expect(payment.receipt).to be_attached
    expect(payment.receipt.filename.to_s).to eq("receipt.png")
    expect(payment.receipt.content_type).to eq("image/png")
    expect(ActiveStorage::Attachment.find_by(record: payment, name: "receipt")).to be_present
  end

  it "updates an existing rejected payment with a new receipt" do
    user, account, provider = setup_payment_account
    payment = account.payments.create!(provider:, status: :rejected, rejection_reason: "Comprobante ilegible")
    payment.receipt.attach(
      io: StringIO.new("old receipt"),
      filename: "old.png",
      content_type: "image/png"
    )
    original_blob_id = payment.receipt.blob_id
    sign_in(user, role: :consumer)

    expect {
      patch payment_path(payment), params: {
        payment: { receipt: receipt_upload(filename: "replacement.png") }
      }, headers: account_page_headers
    }.not_to change(Payment, :count)

    expect(response).to redirect_to(accounts_path)
    expect(payment.reload).to be_submitted
    expect(payment.account).to eq(account)
    expect(payment.provider).to eq(provider)
    expect(payment.receipt).to be_attached
    expect(payment.receipt.filename.to_s).to eq("replacement.png")
    expect(payment.receipt.blob_id).not_to eq(original_blob_id)
  end

  # El mes en curso todavía puede sumar pedidos: no se paga hasta que cierre.
  it "does not create a payment for the account of the current month" do
    user, account, = setup_payment_account
    account.update!(month: Date.current.beginning_of_month)
    sign_in(user, role: :consumer)

    expect {
      post payments_path, params: {
        payment: { account_id: account.id, receipt: receipt_upload }
      }, headers: account_page_headers
    }.not_to change(Payment, :count)

    expect(response).to redirect_to(accounts_path)
    follow_redirect!
    expect(inertia).to have_props(
      errors: { receipt: [ I18n.t("validations.payment_current_account") ] }
    )
  end

  it "does not replace a rejected receipt of the current month" do
    user, account, provider = setup_payment_account
    account.update!(month: Date.current.beginning_of_month)
    payment = account.payments.build(provider:, status: :rejected, rejection_reason: "Comprobante ilegible")
    payment.receipt.attach(io: StringIO.new("old receipt"), filename: "old.png", content_type: "image/png")
    payment.save!
    original_blob_id = payment.receipt.blob_id
    sign_in(user, role: :consumer)

    patch payment_path(payment), params: {
      payment: { receipt: receipt_upload(filename: "replacement.png") }
    }, headers: account_page_headers

    expect(response).to redirect_to(accounts_path)
    expect(payment.reload).to be_rejected
    expect(payment.receipt.blob_id).to eq(original_blob_id)
  end

  it "does not create a payment for an account owned by another consumer" do
    user, = setup_payment_account

    other_user = User.create!(
      email: "other-payment-consumer@gmail.com",
      name: "Other consumer",
      password: "password123456"
    )
    other_consumer = Consumer.create!(
      user: other_user,
      company: Company.first,
      address: "Colonia 1234"
    )
    other_provider_user = User.create!(
      email: "other-payment-provider@gmail.com",
      name: "Other provider",
      password: "password123456"
    )
    other_provider = Provider.create!(user: other_provider_user)
    other_account = Account.create!(
      owner: other_consumer,
      provider: other_provider,
      month: Date.current,
      amount: 250
    )

    sign_in(user, role: :consumer)

    expect {
      post payments_path, params: {
        payment: { account_id: other_account.id, receipt: receipt_upload }
      }, headers: account_page_headers
    }.not_to change(Payment, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "does not replace the receipt of an approved payment" do
    user, account, provider = setup_payment_account
    payment = account.payments.create!(provider:, status: :approved)
    payment.receipt.attach(
      io: StringIO.new("approved receipt"),
      filename: "approved.png",
      content_type: "image/png"
    )
    original_blob_id = payment.receipt.blob_id

    sign_in(user, role: :consumer)

    patch payment_path(payment), params: {
      payment: { receipt: receipt_upload(filename: "forbidden.png") }
    }, headers: account_page_headers

    expect(response).to redirect_to(accounts_path)
    expect(payment.reload).to be_approved
    expect(payment.receipt.blob_id).to eq(original_blob_id)
  end

  it "allows the owner to remove a receipt that is still under review" do
    user, account, provider = setup_payment_account
    payment = submitted_payment(account:, provider:)
    sign_in(user, role: :consumer)

    expect {
      delete payment_path(payment), headers: account_page_headers
    }.to change(Payment, :count).by(-1)

    expect(response).to redirect_to(accounts_path)
    follow_redirect!
    expect(inertia).to have_flash(notice: I18n.t("flash.payment_receipt_removed"))
  end

  it "allows the owner to remove a rejected receipt" do
    user, account, provider = setup_payment_account
    payment = account.payments.build(
      provider:,
      status: :rejected,
      rejection_reason: "Comprobante ilegible"
    )
    payment.receipt.attach(
      io: StringIO.new("rejected receipt"),
      filename: "rejected.png",
      content_type: "image/png"
    )
    payment.save!
    sign_in(user, role: :consumer)

    expect {
      delete payment_path(payment), headers: account_page_headers
    }.to change(Payment, :count).by(-1)

    expect(response).to redirect_to(accounts_path)
  end

  it "does not remove a receipt that has already been reviewed" do
    user, account, provider = setup_payment_account
    payment = account.payments.create!(provider:, status: :approved)
    sign_in(user, role: :consumer)

    expect {
      delete payment_path(payment), headers: account_page_headers
    }.not_to change(Payment, :count)

    expect(response).to redirect_to(accounts_path)
    follow_redirect!
    expect(inertia).to have_flash(alert: I18n.t("validations.payment_not_removable"))
  end

  it "does not allow one consumer to remove another consumer's receipt" do
    user, = setup_payment_account
    other_user = User.create!(
      email: "other-payment-removal-consumer@gmail.com",
      name: "Other consumer",
      password: "password123456"
    )
    other_consumer = Consumer.create!(
      user: other_user,
      company: Company.first,
      address: "Colonia 1234"
    )
    provider = Provider.first
    other_account = Account.create!(
      owner: other_consumer,
      provider:,
      month: Date.current,
      amount: 250
    )
    payment = submitted_payment(account: other_account, provider:)
    sign_in(user, role: :consumer)

    expect {
      delete payment_path(payment), headers: account_page_headers
    }.not_to change(Payment, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "does not allow an unauthenticated user to remove a receipt" do
    _user, account, provider = setup_payment_account
    payment = submitted_payment(account:, provider:)

    expect {
      delete payment_path(payment), headers: account_page_headers
    }.not_to change(Payment, :count)

    expect(response).to redirect_to(sign_in_path)
  end

  it "does not allow a provider to remove a consumer's receipt" do
    _user, account, provider = setup_payment_account
    payment = submitted_payment(account:, provider:)
    sign_in(provider.user, role: :provider)

    expect {
      delete payment_path(payment), headers: account_page_headers
    }.not_to change(Payment, :count)

    expect(response).to redirect_to(root_path)
  end

  it "allows the owner to access the receipt" do
    user, account, provider = setup_payment_account

    payment = account.payments.create!(provider:, status: :pending)
    payment.receipt.attach(
      io: StringIO.new("owner receipt"),
      filename: "owner.png",
      content_type: "image/png"
    )

    sign_in(user, role: :consumer)

    get receipt_payment_path(payment)

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("owner receipt")
  end

  it "does not allow unauthenticated access to the receipt" do
    _user, account, provider = setup_payment_account

    payment = account.payments.create!(provider:, status: :pending)
    payment.receipt.attach(
      io: StringIO.new("private receipt"),
      filename: "private.png",
      content_type: "image/png"
    )

    get receipt_payment_path(payment)

    expect(response).to redirect_to(sign_in_path)
  end

  it "does not allow another consumer to access the receipt" do
    _user, account, provider = setup_payment_account

    payment = account.payments.create!(provider:, status: :pending)
    payment.receipt.attach(
      io: StringIO.new("private receipt"),
      filename: "private.png",
      content_type: "image/png"
    )

    other_user = User.create!(
      email: "other-receipt-consumer@gmail.com",
      name: "Other consumer",
      password: "password123456"
    )

    Consumer.create!(
      user: other_user,
      company: Company.first,
      address: "Colonia 1234"
    )

    sign_in(other_user, role: :consumer)

    get receipt_payment_path(payment)

    expect(response).to have_http_status(:not_found)
  end

  # El lado que la pantalla no puede cubrir: el modelo rechaza el adjunto y el
  # controller tiene que volver con los errores sin dejar el pago a medias.
  it "sends back the errors and persists nothing when the receipt is not an accepted format" do
    user, account, = setup_payment_account
    sign_in(user, role: :consumer)
    text_file = Rack::Test::UploadedFile.new(
      Rails.root.join("public/robots.txt"),
      "text/plain",
      original_filename: "comprobante.txt"
    )

    expect {
      post payments_path, params: {
        payment: { account_id: account.id, receipt: text_file }
      }, headers: account_page_headers
    }.not_to change(Payment, :count)

    expect(response).to redirect_to(accounts_path)
    expect(account.reload.payments).to be_empty
    follow_redirect!
    expect(inertia).to have_props(
      errors: { receipt: [ I18n.t("activerecord.errors.models.payment.attributes.receipt.invalid_content_type") ] }
    )
  end

  it "allows uploading multiple receipts for the same account and serializes them in accounts view" do
    user, account, provider = setup_payment_account
    sign_in(user, role: :consumer)

    expect {
      post payments_path, params: {
        payment: { account_id: account.id, receipt: receipt_upload(filename: "receipt_1.png") }
      }, headers: account_page_headers
    }.to change(Payment, :count).by(1)
    expect(response).to redirect_to(accounts_path)

    expect {
      post payments_path, params: {
        payment: { account_id: account.id, receipt: receipt_upload(filename: "receipt_2.png") }
      }, headers: account_page_headers
    }.to change(Payment, :count).by(1)
    expect(response).to redirect_to(accounts_path)

    expect(account.reload.payments.count).to eq(2)
    expect(account.payments.map(&:status)).to contain_exactly("submitted", "submitted")
    expect(account.payments.map { |p| p.receipt.filename.to_s }).to contain_exactly("receipt_1.png", "receipt_2.png")

    get accounts_path
    expect(response).to have_http_status(:ok)
    expect(inertia).to have_props { |props|
      accounts = props.deep_symbolize_keys[:accounts]
      target_account = accounts.find { |a| a[:id] == account.id }
      payments = target_account[:payments]
      payments.size == 2 &&
        payments.all? { |p| p[:status] == "submitted" && p[:receipt_url].present? && p[:receipt_filename].present? && p[:receipt_uploaded_at].present? }
    }
  end

  it "deletes only the targeted receipt when an account has multiple receipts and preserves the others" do
    user, account, provider = setup_payment_account
    payment1 = submitted_payment(account:, provider:)
    payment2 = account.payments.build(provider:, status: :rejected, rejection_reason: "Foto ilegible")
    payment2.receipt.attach(io: StringIO.new("receipt 2"), filename: "receipt_2.png", content_type: "image/png")
    payment2.save!

    sign_in(user, role: :consumer)
    expect(account.reload.payments.count).to eq(2)

    expect {
      delete payment_path(payment1), headers: account_page_headers
    }.to change(Payment, :count).by(-1)

    expect(response).to redirect_to(accounts_path)
    follow_redirect!
    expect(inertia).to have_flash(notice: I18n.t("flash.payment_receipt_removed"))

    expect(Payment.exists?(payment1.id)).to be(false)
    expect(Payment.exists?(payment2.id)).to be(true)
    expect(payment2.reload.receipt).to be_attached
    expect(account.reload.payments).to contain_exactly(payment2)
  end

  it "does not allow an admin to create a payment" do
    _user, account, = setup_payment_account
    admin_user = User.create!(email: "admin-payment@gmail.com", name: "Admin", password: "password123456")
    Admin.create!(user: admin_user, company: account.owner.company)

    sign_in(admin_user, role: :admin)

    expect {
      post payments_path, params: {
        payment: { account_id: account.id, receipt: receipt_upload }
      }, headers: account_page_headers
    }.not_to change(Payment, :count)

    expect(response).to redirect_to(root_path)
  end

  it "does not allow an admin to remove a consumer's receipt" do
    _user, account, provider = setup_payment_account
    payment = submitted_payment(account:, provider:)
    admin_user = User.create!(email: "admin-removal@gmail.com", name: "Admin", password: "password123456")
    Admin.create!(user: admin_user, company: account.owner.company)

    sign_in(admin_user, role: :admin)

    expect {
      delete payment_path(payment), headers: account_page_headers
    }.not_to change(Payment, :count)

    expect(response).to redirect_to(root_path)
  end

  it "does not allow a provider to create a payment" do
    _user, account, provider = setup_payment_account
    sign_in(provider.user, role: :provider)

    expect {
      post payments_path, params: {
        payment: { account_id: account.id, receipt: receipt_upload }
      }, headers: account_page_headers
    }.not_to change(Payment, :count)

    expect(response).to redirect_to(root_path)
  end

  it "redirects with validation error when receipt parameter is missing" do
    user, account, = setup_payment_account
    sign_in(user, role: :consumer)

    expect {
      post payments_path, params: {
        payment: { account_id: account.id }
      }, headers: account_page_headers
    }.not_to change(Payment, :count)

    expect(response).to redirect_to(accounts_path)
    follow_redirect!
    expect(inertia).to have_props(
      errors: { receipt: [ I18n.t("activerecord.errors.models.payment.attributes.receipt.required") ] }
    )
  end

  it "returns bad request when payment parameter hash is missing" do
    user, = setup_payment_account
    sign_in(user, role: :consumer)

    post payments_path, params: {}, headers: account_page_headers
    expect(response).to have_http_status(:bad_request)
  end

  it "returns not found when deleting a non-existent payment" do
    user, = setup_payment_account
    sign_in(user, role: :consumer)

    delete payment_path(id: 999_999), headers: account_page_headers
    expect(response).to have_http_status(:not_found)
  end

  it "does not remove a receipt that is in pending status" do
    user, account, provider = setup_payment_account
    payment = account.payments.create!(provider:, status: :pending)
    sign_in(user, role: :consumer)

    expect {
      delete payment_path(payment), headers: account_page_headers
    }.not_to change(Payment, :count)

    expect(response).to redirect_to(accounts_path)
    follow_redirect!
    expect(inertia).to have_flash(alert: I18n.t("validations.payment_not_removable"))
    expect(Payment.exists?(payment.id)).to be(true)
  end
end
