# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invoice, type: :model do
  fixtures :users, :companies, :providers, :consumers, :accounts

  let(:account) { accounts(:gogrow_tuviandita_current) }

  def attach_file(invoice, content_type: "application/pdf", filename: "factura.pdf", content: "%PDF-1.4")
    invoice.file.attach(io: StringIO.new(content), filename:, content_type:)
    invoice
  end

  def build_invoice(**attributes)
    attach_file(Invoice.new(account:, issued_on: Date.current, total_amount: 601, **attributes))
  end

  it "starts pending" do
    expect(build_invoice).to be_pending
  end

  it "is valid with an issue date, a total amount and a file" do
    expect(build_invoice).to be_valid
  end

  it "requires the issue date" do
    invoice = build_invoice(issued_on: nil)

    expect(invoice).not_to be_valid
    expect(invoice.errors.details[:issued_on]).to include(error: :blank)
  end

  it "rejects an issue date in the future" do
    invoice = build_invoice(issued_on: Date.current + 1.day)

    expect(invoice).not_to be_valid
    expect(invoice.errors.details[:issued_on]).to include(a_hash_including(error: :less_than_or_equal_to))
  end

  it "requires a positive total amount" do
    expect(build_invoice(total_amount: nil)).not_to be_valid
    expect(build_invoice(total_amount: 0)).not_to be_valid
  end

  it "requires a file" do
    invoice = Invoice.new(account:, issued_on: Date.current, total_amount: 601)

    expect(invoice).not_to be_valid
    expect(invoice.errors.details[:file]).to include(error: :required)
  end

  it "accepts PDF, JPG and PNG files" do
    %w[application/pdf image/jpeg image/png].each do |content_type|
      invoice = attach_file(Invoice.new(account:, issued_on: Date.current, total_amount: 601), content_type:)

      expect(invoice).to be_valid
    end
  end

  it "rejects other file types" do
    invoice = attach_file(Invoice.new(account:, issued_on: Date.current, total_amount: 601), content_type: "text/plain", filename: "factura.txt", content: "texto plano")

    expect(invoice).not_to be_valid
    expect(invoice.errors.details[:file]).to include(error: :invalid_content_type)
  end

  it "rejects files over 10 MB" do
    invoice = attach_file(Invoice.new(account:, issued_on: Date.current, total_amount: 601), content: "a" * (10.megabytes + 1))

    expect(invoice).not_to be_valid
    expect(invoice.errors.details[:file]).to include(error: :too_large)
  end

  it "only belongs to a company account" do
    invoice = build_invoice(account: accounts(:one_tuviandita_current))

    expect(invoice).not_to be_valid
    expect(invoice.errors.details[:account]).to include(error: :not_company)
  end

  describe "a new invoice for the same period" do
    it "is not allowed while the last one is pending" do
      build_invoice.save!

      invoice = build_invoice

      expect(invoice).not_to be_valid
      expect(invoice.errors.details[:base]).to include(error: :already_invoiced)
    end

    it "is not allowed once the last one is approved" do
      build_invoice(status: :approved).save!

      expect(build_invoice).not_to be_valid
    end

    it "is allowed after the last one was rejected" do
      build_invoice(status: :rejected).save!

      expect(build_invoice).to be_valid
    end

    it "does not block updating the current invoice" do
      invoice = build_invoice
      invoice.save!

      expect(invoice.reload).to be_valid
    end

    it "is rejected by the database even when the validation is skipped" do
      build_invoice.save!

      expect { build_invoice.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  it "can only be removed while pending" do
    expect(build_invoice).to be_removable
    expect(build_invoice(status: :approved)).not_to be_removable
    expect(build_invoice(status: :rejected)).not_to be_removable
  end
end

# == Schema Information
#
# Table name: invoices
#
#  id           :bigint           not null, primary key
#  issued_on    :date             not null
#  status       :integer          default(0), not null
#  total_amount :decimal(10, 2)   not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#
# Indexes
#
#  index_invoices_on_account_id         (account_id)
#  index_invoices_on_account_id_active  (account_id) UNIQUE WHERE (status = ANY (ARRAY[0, 1]))
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
