# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Payments", type: :request do
  fixtures :users, :companies, :admins, :providers, :consumers, :menus, :schedules,
           :orders, :accounts, :order_accounts, :payments

  # La cuenta de otra empresa se crea acá y no en los fixtures: las cuentas se
  # cuentan en los specs de cobros y una fila más les cambiaría los totales.
  let(:other_company_account) do
    company = Company.create!(name: "Otra empresa", address: "Rincón 500")

    Account.create!(owner: company, provider: providers(:tuviandita), month: Date.current, amount: 100.00)
  end

  def receipt_upload(content_type: "image/png", filename: "comprobante.png")
    Rack::Test::UploadedFile.new(
      Rails.root.join(content_type == "text/plain" ? "public/robots.txt" : "public/icon.png"),
      content_type,
      original_filename: filename
    )
  end

  def oversized_receipt
    Tempfile.create([ "comprobante-grande", ".png" ]) do |file|
      file.binmode
      file.write("x" * (10.megabytes + 1))
      file.rewind

      yield Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: "comprobante-grande.png")
    end
  end

  describe "GET /admin/payments" do
    it "redirects to sign in without a session" do
      get admin_payments_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects a consumer to the home page" do
      sign_in users(:one), role: :consumer

      get admin_payments_path

      expect(response).to redirect_to(root_path)
    end

    context "when signed in as HR" do
      before { sign_in users(:admin), role: :admin }

      it "lists only what the company still owes, and not what its employees owe" do
        other_company_account

        get admin_payments_path

        expect(inertia).to render_component("admin/payments/index")
        expect(inertia.props[:accounts].pluck(:id)).to contain_exactly(accounts(:gogrow_tuviandita_current).id)
        expect(inertia.props[:total_debt]).to eq(601.0)
      end

      it "moves a period with an approved receipt to the history" do
        get admin_payments_path

        expect(inertia.props[:history].pluck(:id)).to contain_exactly(accounts(:gogrow_tuviandita_previous).id)
      end

      it "counts the subsidy and the meals of the current month" do
        get admin_payments_path

        expect(inertia.props[:current_month]).to eq("amount" => 601.0, "meals" => 4, "limit" => 40)
      end

      it "lists every provider so the ones without debt also show up" do
        get admin_payments_path

        expect(inertia.props[:providers].pluck(:name))
          .to eq([ "Office Provider User", "Other Provider User", "Provider User" ])
      end
    end
  end

  describe "GET /admin/payments/:id" do
    it "redirects to sign in without a session" do
      get admin_payment_path(accounts(:gogrow_tuviandita_current))

      expect(response).to redirect_to(sign_in_path)
    end

    it "answers with the confirmed orders that make up the period" do
      sign_in users(:admin), role: :admin

      get admin_payment_path(accounts(:gogrow_tuviandita_current))

      body = response.parsed_body

      expect(body["month"]).to eq(I18n.l(Date.current, format: :month_year))
      expect(body["amount"]).to eq(601.0)
      expect(body["orders"].pluck("id")).to contain_exactly(
        orders(:upcoming_confirmed_future).id,
        orders(:history_confirmed_past).id,
        orders(:other_consumer_upcoming).id
      )
    end

    it "responds with not found for an account of another company" do
      sign_in users(:admin), role: :admin

      get admin_payment_path(other_company_account)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /admin/payments" do
    let(:account) { accounts(:gogrow_tuviandita_current) }

    it "creates a submitted payment with a receipt for the company account" do
      sign_in users(:admin), role: :admin

      expect {
        post admin_payments_path, params: {
          payment: { account_id: account.id, receipt: receipt_upload }
        }, headers: { "HTTP_REFERER" => admin_payments_url }
      }.to change(Payment, :count).by(1)

      payment = account.payments.reload.order(:created_at).last
      expect(response).to redirect_to(admin_payments_path)
      expect(payment).to be_submitted
      expect(payment.provider).to eq(account.provider)
      expect(payment.receipt).to be_attached
      expect(payment.receipt.filename.to_s).to eq("comprobante.png")
    end

    it "allows multiple receipts for the same company account" do
      sign_in users(:admin), role: :admin

      2.times do |index|
        post admin_payments_path, params: {
          payment: {
            account_id: account.id,
            receipt: receipt_upload(filename: "comprobante_#{index + 1}.png")
          }
        }, headers: { "HTTP_REFERER" => admin_payments_url }
      end

      expect(account.payments.reload.last(2).map(&:status)).to eq([ "submitted", "submitted" ])
      expect(account.payments.last(2).map { it.receipt.filename.to_s })
        .to eq([ "comprobante_1.png", "comprobante_2.png" ])
    end

    it "does not create a payment for another company's account" do
      sign_in users(:admin), role: :admin

      expect {
        post admin_payments_path, params: {
          payment: { account_id: other_company_account.id, receipt: receipt_upload }
        }
      }.not_to change(Payment, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "returns the shared file validation errors" do
      sign_in users(:admin), role: :admin

      expect {
        post admin_payments_path, params: {
          payment: {
            account_id: account.id,
            receipt: receipt_upload(content_type: "text/plain", filename: "comprobante.txt")
          }
        }, headers: { "HTTP_REFERER" => admin_payments_url }
      }.not_to change(Payment, :count)

      follow_redirect!
      expect(inertia).to have_props(
        errors: {
          receipt: [ I18n.t("activerecord.errors.models.payment.attributes.receipt.invalid_content_type") ]
        }
      )
    end

    it "rejects a receipt larger than 10 MB without persisting the payment" do
      sign_in users(:admin), role: :admin

      oversized_receipt do |receipt|
        expect {
          post admin_payments_path, params: {
            payment: { account_id: account.id, receipt: }
          }, headers: { "HTTP_REFERER" => admin_payments_url }
        }.not_to change(Payment, :count)
      end

      follow_redirect!
      expect(inertia).to have_props(
        errors: {
          receipt: [ I18n.t("activerecord.errors.models.payment.attributes.receipt.too_large") ]
        }
      )
    end

    it "requires a receipt" do
      sign_in users(:admin), role: :admin

      expect {
        post admin_payments_path, params: {
          payment: { account_id: account.id }
        }, headers: { "HTTP_REFERER" => admin_payments_url }
      }.not_to change(Payment, :count)

      follow_redirect!
      expect(inertia).to have_props(
        errors: {
          receipt: [ I18n.t("activerecord.errors.models.payment.attributes.receipt.required") ]
        }
      )
    end

    it "does not allow a consumer to upload a company receipt" do
      sign_in users(:one), role: :consumer

      expect {
        post admin_payments_path, params: {
          payment: { account_id: account.id, receipt: receipt_upload }
        }
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(root_path)
    end

    it "requires an admin session" do
      expect {
        post admin_payments_path, params: {
          payment: { account_id: account.id, receipt: receipt_upload }
        }
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "GET /admin/payments/:id/receipt" do
    let(:account) { accounts(:gogrow_tuviandita_current) }

    it "allows HR to access a receipt from its company account" do
      payment = account.payments.build(provider: account.provider, status: :submitted)
      payment.receipt.attach(io: StringIO.new("company receipt"), filename: "receipt.png", content_type: "image/png")
      payment.save!
      sign_in users(:admin), role: :admin

      get receipt_admin_payment_path(payment)

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("company receipt")
    end

    it "does not expose receipts from another company" do
      payment = other_company_account.payments.build(
        provider: other_company_account.provider,
        status: :submitted
      )
      payment.receipt.attach(io: StringIO.new("private"), filename: "private.png", content_type: "image/png")
      payment.save!
      sign_in users(:admin), role: :admin

      get receipt_admin_payment_path(payment)

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      payment = account.payments.build(provider: account.provider, status: :submitted)
      payment.receipt.attach(io: StringIO.new("private"), filename: "private.png", content_type: "image/png")
      payment.save!

      get receipt_admin_payment_path(payment)

      expect(response).to redirect_to(sign_in_path)
    end

    it "does not allow a consumer to access a company receipt" do
      payment = account.payments.build(provider: account.provider, status: :submitted)
      payment.receipt.attach(io: StringIO.new("private"), filename: "private.png", content_type: "image/png")
      payment.save!
      sign_in users(:one), role: :consumer

      get receipt_admin_payment_path(payment)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /admin/payments/:id" do
    let(:account) { accounts(:gogrow_tuviandita_current) }

    def payment_with_receipt(status:, rejection_reason: nil)
      payment = account.payments.build(provider: account.provider, status:, rejection_reason:)
      payment.receipt.attach(io: StringIO.new("receipt"), filename: "receipt.png", content_type: "image/png")
      payment.save!
      payment
    end

    it "removes a receipt under review" do
      payment = payment_with_receipt(status: :submitted)
      sign_in users(:admin), role: :admin

      expect {
        delete admin_payment_path(payment), headers: { "HTTP_REFERER" => admin_payments_url }
      }.to change(Payment, :count).by(-1)

      follow_redirect!
      expect(inertia).to have_flash(notice: I18n.t("flash.payment_receipt_removed"))
    end

    it "removes a rejected receipt" do
      payment = payment_with_receipt(status: :rejected, rejection_reason: "Comprobante ilegible")
      sign_in users(:admin), role: :admin

      expect {
        delete admin_payment_path(payment), headers: { "HTTP_REFERER" => admin_payments_url }
      }.to change(Payment, :count).by(-1)
    end

    it "does not remove an approved receipt" do
      payment = payment_with_receipt(status: :approved)
      sign_in users(:admin), role: :admin

      expect {
        delete admin_payment_path(payment), headers: { "HTTP_REFERER" => admin_payments_url }
      }.not_to change(Payment, :count)

      expect(payment.reload).to be_approved
    end

    it "does not remove a receipt from another company" do
      payment = other_company_account.payments.build(
        provider: other_company_account.provider,
        status: :submitted
      )
      payment.receipt.attach(io: StringIO.new("private"), filename: "private.png", content_type: "image/png")
      payment.save!
      sign_in users(:admin), role: :admin

      expect {
        delete admin_payment_path(payment)
      }.not_to change(Payment, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      payment = payment_with_receipt(status: :submitted)

      expect {
        delete admin_payment_path(payment)
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(sign_in_path)
    end

    it "does not allow a consumer to remove a company receipt" do
      payment = payment_with_receipt(status: :submitted)
      sign_in users(:one), role: :consumer

      expect {
        delete admin_payment_path(payment)
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(root_path)
    end
  end
end
