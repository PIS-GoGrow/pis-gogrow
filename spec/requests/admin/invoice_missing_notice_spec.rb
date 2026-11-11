# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Aviso Falta una factura en el Inicio de RR. HH.", type: :request do
  fixtures :users, :companies, :admins, :consumers, :providers, :accounts, :payments

  let(:account) do
    Account.create!(owner: companies(:gogrow), provider: providers(:endulzate), month: Date.current.beginning_of_month - 1.month, amount: 4500)
  end

  before do
    allow(WhatsappSenderJob).to receive(:perform_later)
    sign_in users(:admin), role: :admin
  end

  def titles
    inertia.props[:notifications].pluck(:title)
  end

  it "muestra el aviso de un mes cerrado sin factura" do
    account
    InvoiceReminders::MissingNotices.remind!

    get admin_dashboard_path

    expect(titles).to include("Falta una factura")
  end

  it "no lo muestra para el mes en curso" do
    Account.create!(owner: companies(:gogrow), provider: providers(:endulzate), month: Date.current.beginning_of_month, amount: 4500)
    InvoiceReminders::MissingNotices.remind!

    get admin_dashboard_path

    expect(titles).not_to include("Falta una factura")
  end

  it "no vuelve a aparecer después de cerrarlo con la ×" do
    account
    InvoiceReminders::MissingNotices.remind!
    notice = Notification.find_by!(event: "hr_invoice_missing", notifiable: account)

    patch close_notification_path(notice)
    InvoiceReminders::MissingNotices.remind!
    get admin_dashboard_path

    expect(titles).not_to include("Falta una factura")
  end
end
