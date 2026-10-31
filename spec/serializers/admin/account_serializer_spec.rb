# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AccountSerializer do
  include Rails.application.routes.url_helpers

  fixtures :users, :companies, :providers, :accounts, :payments

  let(:account) { accounts(:gogrow_tuviandita_previous) }
  let(:payment) { payments(:gogrow_previous_approved) }

  def dummy_upload(filename: "comprobante.png", content_type: "image/png")
    Rack::Test::UploadedFile.new(
      Rails.root.join("public/icon.png"),
      content_type,
      original_filename: filename
    )
  end

  describe "#to_h" do
    context "when account has an approved payment with an attached receipt" do
      before do
        payment.receipt.attach(dummy_upload)
      end

      it "serializes paid_on and receipt_download_url" do
        serialized = described_class.new(account).to_h

        expect(serialized["paid_on"]).to eq(DateFormat.short(payment.created_at))
        expect(serialized["receipt_download_url"]).to eq(receipt_admin_payment_path(payment))
      end
    end

    context "when account has multiple approved payments" do
      let!(:newer_payment) do
        account.payments.create!(
          provider: account.provider,
          status: :approved,
          created_at: payment.created_at + 2.days
        ).tap do |p|
          p.receipt.attach(dummy_upload(filename: "nuevo.png"))
        end
      end

      it "picks the newest approved payment by created_at" do
        payment.receipt.attach(dummy_upload(filename: "viejo.png"))
        serialized = described_class.new(account).to_h

        expect(serialized["paid_on"]).to eq(DateFormat.short(newer_payment.created_at))
        expect(serialized["receipt_download_url"]).to eq(receipt_admin_payment_path(newer_payment))
      end
    end

    context "when approved payment does not have an attached receipt" do
      it "serializes paid_on but leaves receipt_download_url as nil" do
        payment.receipt.purge if payment.receipt.attached?
        serialized = described_class.new(account).to_h

        expect(serialized["paid_on"]).to eq(DateFormat.short(payment.created_at))
        expect(serialized["receipt_download_url"]).to be_nil
      end
    end

    context "when account has no approved payments" do
      let(:unpaid_account) { accounts(:gogrow_tuviandita_current) }

      it "leaves paid_on and receipt_download_url as nil" do
        serialized = described_class.new(unpaid_account).to_h

        expect(serialized["paid_on"]).to be_nil
        expect(serialized["receipt_download_url"]).to be_nil
      end
    end

    context "when account has an approved invoice" do
      let!(:approved_invoice) do
        account.invoices.create!(
          issued_on: Date.current,
          total_amount: 500,
          status: :approved,
          file: dummy_upload(filename: "factura.png")
        )
      end

      it "serializes invoice_download_url pointing to the invoice file with download=1" do
        serialized = described_class.new(account).to_h

        expect(serialized["invoice_download_url"]).to eq(file_admin_invoice_path(approved_invoice, download: 1))
      end
    end

    context "when account has a rejected invoice" do
      before do
        account.invoices.create!(
          issued_on: Date.current,
          total_amount: 500,
          status: :rejected,
          file: dummy_upload(filename: "factura_rechazada.png")
        )
      end

      it "leaves invoice_download_url as nil" do
        serialized = described_class.new(account).to_h

        expect(serialized["invoice_download_url"]).to be_nil
      end
    end

    context "when account has no invoices" do
      it "leaves invoice_download_url as nil" do
        serialized = described_class.new(account).to_h

        expect(serialized["invoice_download_url"]).to be_nil
      end
    end
  end
end
