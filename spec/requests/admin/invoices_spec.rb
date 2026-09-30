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
