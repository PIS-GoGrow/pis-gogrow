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
    account = Account.create!(owner: consumer, provider:, month: Date.current, amount: 500)

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
    payment = account.payments.create!(provider:, status: :rejected)
    payment.receipt.attach(io: StringIO.new("old receipt"), filename: "old.png", content_type: "image/png")
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

  it "does not create a payment for an account owned by another consumer" do
    user, = setup_payment_account
    other_user = User.create!(email: "other-payment-consumer@gmail.com", name: "Other consumer", password: "password123456")
    other_consumer = Consumer.create!(user: other_user, company: Company.first, address: "Colonia 1234")
    other_provider_user = User.create!(email: "other-payment-provider@gmail.com", name: "Other provider", password: "password123456")
    other_provider = Provider.create!(user: other_provider_user)
    other_account = Account.create!(owner: other_consumer, provider: other_provider, month: Date.current, amount: 250)
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
    payment.receipt.attach(io: StringIO.new("approved receipt"), filename: "approved.png", content_type: "image/png")
    original_blob_id = payment.receipt.blob_id
    sign_in(user, role: :consumer)

    patch payment_path(payment), params: {
      payment: { receipt: receipt_upload(filename: "forbidden.png") }
    }, headers: account_page_headers

    expect(response).to redirect_to(accounts_path)
    expect(payment.reload).to be_approved
    expect(payment.receipt.blob_id).to eq(original_blob_id)
  end
end
