# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Invoices", type: :request do
  fixtures :users, :companies, :admins, :providers, :consumers, :accounts

  let(:invoice) do
    Invoice.create!(
      account: accounts(:gogrow_tuviandita_current),
      issued_on: Date.current,
      total_amount: 601,
      file: Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png", original_filename: "factura.png")
    )
  end

  def upload(name = "factura.png")
    Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png", original_filename: name)
  end

  describe "GET /admin/invoices" do
    it "redirects visitors to the sign in page" do
      get admin_invoices_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects a provider to the home page" do
      sign_in users(:provider_user), role: :provider

      get admin_invoices_path

      expect(response).to redirect_to(root_path)
    end

    context "when signed in as HR" do
      before { sign_in users(:admin), role: :admin }

      it "lists the invoices of the company, newest period first" do
        previous = Invoice.create!(account: accounts(:gogrow_tuviandita_previous), issued_on: Date.current - 1.month, total_amount: 900, file: upload)
        current = invoice

        get admin_invoices_path

        expect(inertia).to render_component("admin/invoices/index")
        expect(inertia).to have_props { |props| props[:invoices].pluck(:id) == [ current.id, previous.id ] }
      end

      it "exposes what HR needs to back the payment" do
        invoice

        get admin_invoices_path

        expect(inertia.props[:invoices].first).to include(
          status: "pending",
          provider_name: users(:provider_user).name,
          issued_on: I18n.l(Date.current, format: "%d/%m/%y"),
          total_amount: 601.0,
          period_amount: 601.0,
          file_name: "factura.png"
        )
      end

      # El consumo del período es de la cuenta y la factura la emite el
      # proveedor: pueden no coincidir, y es justamente lo que RR. HH. compara.
      it "keeps the invoiced total apart from what the period consumed" do
        Invoice.create!(account: accounts(:gogrow_tuviandita_previous), issued_on: Date.current - 1.month, total_amount: 123.45, file: upload)

        get admin_invoices_path

        billed = inertia.props[:invoices].find { it[:total_amount] == 123.45 }
        expect(billed[:period_amount]).to eq(900.0)
      end

      it "leaves out the invoices of another company" do
        other_company = Company.create!(name: "Otra", address: "Rivera 1234")
        other_account = Account.create!(owner: other_company, provider: providers(:tuviandita), month: Date.current.beginning_of_month, amount: 100)
        hidden = Invoice.create!(account: other_account, issued_on: Date.current, total_amount: 100, file: upload)

        get admin_invoices_path

        expect(inertia.props[:invoices].pluck(:id)).not_to include(hidden.id)
      end

      it "renders the empty state with no invoices" do
        get admin_invoices_path

        expect(inertia).to have_props(invoices: [])
      end
    end
  end

  describe "GET /admin/invoices/:id/file" do
    it "lets HR open the invoice of any provider" do
      sign_in users(:admin), role: :admin

      get file_admin_invoice_path(invoice)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/png")
      expect(response.headers["Content-Disposition"]).to start_with("inline")
    end

    it "lets HR download it" do
      sign_in users(:admin), role: :admin

      get file_admin_invoice_path(invoice, download: 1)

      expect(response.headers["Content-Disposition"]).to start_with("attachment")
    end

    it "redirects a provider to the home page, even the one who issued it" do
      sign_in users(:provider_user), role: :provider

      get file_admin_invoice_path(invoice)

      expect(response).to redirect_to(root_path)
    end

    it "redirects another provider to the home page" do
      sign_in users(:other_provider_user), role: :provider

      get file_admin_invoice_path(invoice)

      expect(response).to redirect_to(root_path)
    end
  end
end
