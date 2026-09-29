# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::Invoices", type: :request do
  fixtures :users, :companies, :providers, :consumers, :accounts

  let(:provider_user) { users(:provider_user) }
  let(:account) { accounts(:gogrow_tuviandita_current) }
  let(:collections_headers) { { "HTTP_REFERER" => provider_collections_url } }

  def invoice_upload(filename: "factura.png")
    Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png", original_filename: filename)
  end

  def invoice_params(**overrides)
    { invoice: { account_id: account.id, issued_on: Date.current.to_s, total_amount: "601", file: invoice_upload }.merge(overrides) }
  end

  def create_invoice(for_account: account, status: :pending)
    Invoice.create!(account: for_account, issued_on: Date.current, total_amount: 601, status:, file: invoice_upload)
  end

  def endulzate_company_account
    Account.create!(owner: companies(:gogrow), provider: providers(:endulzate), month: Date.current, amount: 300)
  end

  describe "POST /provider/invoices" do
    it "redirects a consumer to the home page" do
      sign_in users(:one), role: :consumer

      expect {
        post provider_invoices_path, params: invoice_params
      }.not_to change(Invoice, :count)

      expect(response).to redirect_to(root_path)
    end

    it "registers a pending invoice for the period of the signed in provider" do
      sign_in provider_user, role: :provider

      expect {
        post provider_invoices_path, params: invoice_params, headers: collections_headers
      }.to change(Invoice, :count).by(1)

      invoice = account.invoices.sole
      expect(response).to redirect_to(provider_collections_path)
      expect(invoice).to be_pending
      expect(invoice.issued_on).to eq(Date.current)
      expect(invoice.total_amount).to eq(601)
      expect(invoice.file.filename.to_s).to eq("factura.png")
      expect(providers(:tuviandita).invoices).to include(invoice)

      follow_redirect!
      expect(inertia).to have_flash(notice: I18n.t("flash.invoice_uploaded"))
    end

    it "returns the errors of each missing field without saving anything" do
      sign_in provider_user, role: :provider

      expect {
        post provider_invoices_path, params: invoice_params(issued_on: "", total_amount: "", file: nil), headers: collections_headers
      }.not_to change(Invoice, :count)

      expect(response).to redirect_to(provider_collections_path)
      follow_redirect!
      expect(inertia.props[:errors].keys).to include("issued_on", "total_amount", "file")
    end

    it "rejects a file that is not PDF, JPG or PNG" do
      sign_in provider_user, role: :provider
      text_file = Rack::Test::UploadedFile.new(StringIO.new("texto plano"), "text/plain", original_filename: "factura.txt")

      expect {
        post provider_invoices_path, params: invoice_params(file: text_file), headers: collections_headers
      }.not_to change(Invoice, :count)

      follow_redirect!
      expect(inertia.props[:errors]).to include("file" => [ I18n.t("activerecord.errors.models.invoice.attributes.file.invalid_content_type") ])
    end

    it "does not find the period of another provider" do
      sign_in provider_user, role: :provider

      expect {
        post provider_invoices_path, params: invoice_params(account_id: endulzate_company_account.id)
      }.not_to change(Invoice, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "does not find the account of an employee" do
      sign_in provider_user, role: :provider

      post provider_invoices_path, params: invoice_params(account_id: accounts(:one_tuviandita_current).id)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /provider/invoices/:id" do
    it "removes a pending invoice" do
      invoice = create_invoice
      sign_in provider_user, role: :provider

      expect {
        delete provider_invoice_path(invoice), headers: collections_headers
      }.to change(Invoice, :count).by(-1)

      expect(response).to redirect_to(provider_collections_path)
      follow_redirect!
      expect(inertia).to have_flash(notice: I18n.t("flash.invoice_removed"))
    end

    it "keeps an invoice that was already reviewed" do
      invoice = create_invoice(status: :approved)
      sign_in provider_user, role: :provider

      expect {
        delete provider_invoice_path(invoice), headers: collections_headers
      }.not_to change(Invoice, :count)

      follow_redirect!
      expect(inertia).to have_flash(alert: I18n.t("validations.invoice_not_removable"))
    end

    it "does not find the invoice of another provider" do
      invoice = create_invoice(for_account: endulzate_company_account)
      sign_in provider_user, role: :provider

      expect {
        delete provider_invoice_path(invoice)
      }.not_to change(Invoice, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /provider/invoices/:id/file" do
    it "shows the file inline to preview it" do
      invoice = create_invoice
      sign_in provider_user, role: :provider

      get file_provider_invoice_path(invoice)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/png")
      expect(response.headers["Content-Disposition"]).to start_with("inline")
    end

    it "sends the file as a download when asked to" do
      invoice = create_invoice
      sign_in provider_user, role: :provider

      get file_provider_invoice_path(invoice, download: 1)

      expect(response.headers["Content-Disposition"]).to start_with("attachment")
      expect(response.headers["Content-Disposition"]).to include("factura.png")
    end

    it "does not show the file of another provider" do
      invoice = create_invoice(for_account: endulzate_company_account)
      sign_in provider_user, role: :provider

      get file_provider_invoice_path(invoice)

      expect(response).to have_http_status(:not_found)
    end
  end
end
