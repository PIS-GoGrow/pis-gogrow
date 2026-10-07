# frozen_string_literal: true

# Historia IBP-042: "Como RRHH, quiero visualizar los recibos o facturas que el
# proveedor emite a GoGrow, para respaldar los pagos de la empresa y disponer de
# su historial."
#
# Los formatos de CA2 figuran "[POR DEFINIR]" en la historia; se toma lo que hoy
# acepta Invoice::ALLOWED_CONTENT_TYPES (PDF, JPG, PNG).

require "rails_helper"

RSpec.describe "Visualizar facturas de proveedores", type: :system do
  fixtures :users, :companies, :admins, :providers, :consumers, :accounts

  let(:admin_user) { users(:admin) }

  def create_invoice(account, total_amount:, issued_on: Date.current, name: "factura.png")
    Invoice.create!(
      account: account,
      issued_on: issued_on,
      total_amount: total_amount,
      file: Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png", original_filename: name)
    )
  end

  def invoice_row(text)
    find("tr", text: text)
  end

  it "reaches the invoices from the navigation and explains when there are none" do
    sign_in admin_user, role: :admin
    visit admin_dashboard_path

    within("[data-sidebar='sidebar']") { click_on "Facturas" }

    expect(page).to have_current_path(admin_invoices_path)
    expect(page).to have_content("Todavía no hay facturas")
    expect(page).to have_no_table
  end

  it "shows every invoice with issue date, provider, period and total, newest period first" do
    current_month = accounts(:gogrow_tuviandita_current).month
    previous_month = accounts(:gogrow_tuviandita_previous).month
    create_invoice(accounts(:gogrow_tuviandita_previous), total_amount: 900, issued_on: Date.current - 1.month)
    create_invoice(accounts(:gogrow_tuviandita_current), total_amount: 601)

    sign_in admin_user, role: :admin
    visit admin_invoices_path

    expect(page).to have_css("tbody tr", count: 2)
    expect(first("tbody tr")).to have_content(/#{I18n.l(current_month, format: "%B %Y")}/i)
    expect(all("tbody tr").last).to have_content(/#{I18n.l(previous_month, format: "%B %Y")}/i)

    within(first("tbody tr")) do
      expect(page).to have_content(users(:provider_user).name)
      expect(page).to have_content(I18n.l(Date.current, format: "%d/%m/%y"))
      expect(page).to have_content(/601/)
    end
  end

  it "previews the file in the browser and offers it as a download" do
    invoice = create_invoice(accounts(:gogrow_tuviandita_current), total_amount: 601, name: "factura-sep.png")

    sign_in admin_user, role: :admin
    visit admin_invoices_path

    view = find_link("Ver")
    expect(view[:target]).to eq("_blank")
    expect(find_link("Descargar factura-sep.png")[:href]).to end_with(file_admin_invoice_path(invoice, download: 1))

    # Abrir el enlace con la sesión real: el navegador muestra la imagen en vez
    # de redirigir al login.
    visit view[:href]
    expect(page).to have_current_path(file_admin_invoice_path(invoice))
    expect(page).to have_css("img")
  end

  it "keeps the invoices after a reload and a new session" do
    create_invoice(accounts(:gogrow_tuviandita_current), total_amount: 601)

    sign_in admin_user, role: :admin
    visit admin_invoices_path
    expect(page).to have_css("tbody tr", count: 1)

    refresh
    expect(page).to have_css("tbody tr", count: 1)

    sign_out
    sign_in admin_user, role: :admin
    visit admin_invoices_path
    expect(invoice_row(users(:provider_user).name)).to have_content(/601/)
  end

  # Lo que el proveedor ve en su cobro y lo que RR. HH. ve en el listado tienen
  # que coincidir: misma factura, mismo monto, mismo período.
  it "shows HR the same amount and period the provider sees on its invoice" do
    account = accounts(:gogrow_tuviandita_current)
    create_invoice(account, total_amount: 589.5, name: "factura-tuviandita.png")

    sign_in users(:provider_user), role: :provider
    visit provider_collections_path
    find("button", text: "Empresa").click
    expect(page).to have_content("Por revisar")
    expect(page).to have_link("Ver factura factura-tuviandita.png")
    sign_out

    sign_in admin_user, role: :admin
    visit admin_invoices_path
    row = invoice_row("Provider User")
    expect(row).to have_content(/589[.,]5/)
    expect(row).to have_content(/#{I18n.l(account.month, format: "%B %Y")}/i)
    expect(row).to have_content("Por revisar")
  end

  describe "permissions" do
    let!(:invoice) { create_invoice(accounts(:gogrow_tuviandita_current), total_amount: 601) }

    it "sends a visitor to sign in" do
      visit admin_invoices_path

      expect(page).to have_current_path(sign_in_path)
    end

    it "keeps a provider out of the list and the file, even the one who issued it" do
      sign_in users(:provider_user), role: :provider

      visit admin_invoices_path
      expect(page).to have_no_current_path(admin_invoices_path)

      visit file_admin_invoice_path(invoice)
      expect(page).to have_no_current_path(file_admin_invoice_path(invoice))
    end

    it "keeps a consumer out of the list" do
      sign_in users(:one), role: :consumer

      visit admin_invoices_path

      expect(page).to have_no_current_path(admin_invoices_path)
    end
  end
end
