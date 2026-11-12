# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoiceReminders::MissingNotices do
  fixtures :users, :companies, :admins, :consumers, :providers, :accounts, :payments

  let(:admin_user) { users(:admin) }
  let(:provider) { providers(:endulzate) }
  let(:closed_month) { Date.current.beginning_of_month - 1.month }
  let(:account) { Account.create!(owner: companies(:gogrow), provider:, month: closed_month, amount: 4500) }

  # Ningún test habla con Twilio: alcanza con saber que el envío se encoló.
  before { allow(WhatsappSenderJob).to receive(:perform_later) }

  def upload
    Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png", original_filename: "factura.png")
  end

  def notices(target = account)
    Notification.where(event: "hr_invoice_missing", notifiable: target)
  end

  describe ".remind!" do
    it "avisa a RR. HH. de un mes cerrado con deuda que el proveedor no facturó" do
      account

      described_class.remind!

      notice = notices.sole
      expect(notice).to have_attributes(user: admin_user, role: "admin", requires_action: false)
      expect(notice.title).to eq("Falta una factura")
      expect(notice.description).to eq(
        "#{provider.user.name} todavía no envió la factura de " \
        "#{I18n.l(closed_month, format: :month_name_year)}. Podés recordarle el envío desde Pagos."
      )
    end

    it "no avisa si el proveedor ya envió la factura" do
      account.invoices.create!(issued_on: Date.current, total_amount: 4500, file: upload)

      described_class.remind!

      expect(notices).to be_empty
    end

    it "no avisa por el mes en curso" do
      current = Account.create!(owner: companies(:gogrow), provider:, month: Date.current.beginning_of_month, amount: 4500)

      described_class.remind!

      expect(notices(current)).to be_empty
    end

    it "no avisa por un período ya pagado" do
      described_class.remind!

      expect(notices(accounts(:gogrow_tuviandita_previous))).to be_empty
    end

    it "crea un solo aviso aunque el job corra todos los días" do
      account

      described_class.remind!
      travel(1.day) { described_class.remind! }

      expect(notices.count).to eq(1)
    end

    it "no vuelve a avisar si RR. HH. lo cerró" do
      account
      described_class.remind!
      notices.sole.close!

      travel(1.day) { described_class.remind! }

      expect(notices.count).to eq(1)
      expect(notices.active).to be_empty
    end
  end

  describe "al subir la factura" do
    it "cierra el aviso de RR. HH." do
      account
      described_class.remind!

      account.invoices.create!(issued_on: Date.current, total_amount: 4500, file: upload)

      expect(notices.active).to be_empty
    end
  end
end
