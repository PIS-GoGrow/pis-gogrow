# frozen_string_literal: true

require "rails_helper"

# Regresión del arreglo de Pagos de RR. HH.: en los períodos cerrados la
# tarjeta ofrece "Descargar factura" o "Recordar envío de factura", según haya
# factura vigente o no; el mes en curso no muestra acciones.
RSpec.describe "Acciones de factura en Pagos de RR. HH.", type: :system do
  fixtures :users, :companies, :admins, :providers, :consumers, :accounts, :payments

  let(:admin_user) { users(:admin) }
  let(:provider) { providers(:tuviandita) }
  let(:closed_month) { 2.months.ago.beginning_of_month }

  before do
    allow(WhatsappSenderJob).to receive(:perform_later)
    sign_in admin_user, role: :admin

    @without_invoice = Account.create!(
      owner: companies(:gogrow), provider:, month: closed_month, amount: 500
    )
    @with_invoice = Account.create!(
      owner: companies(:gogrow), provider:, month: closed_month - 1.month, amount: 600
    )
    Invoice.create!(
      account: @with_invoice,
      issued_on: Date.current,
      total_amount: 600,
      file: Rack::Test::UploadedFile.new(
        Rails.root.join("public/icon.png"), "image/png", original_filename: "factura.png"
      )
    )
  end

  def card_for(amount)
    # La tarjeta del proveedor contiene a las de cada período; la última es la
    # tarjeta interna del período.
    all("[data-slot='card']", text: amount).last
  end

  it "ofrece descargar o recordar la factura según el período" do
    visit_hydrated admin_payments_path
    without_animations

    without_invoice = card_for("$500")
    within(without_invoice) do
      expect(page).to have_no_css("[data-status]")
      expect(page).to have_button("Recordar envío de factura")
      expect(page).to have_no_link("Descargar factura")
      expect(page).to have_content(
        "Podrás enviar el comprobante cuando el proveedor cargue sus datos de cobro."
      )
    end

    within(card_for("$600")) do
      expect(page).to have_link("Descargar factura")
      expect(page).to have_no_button("Recordar envío de factura")
    end

    within(card_for("$601")) do
      expect(page).to have_no_link("Descargar factura")
      expect(page).to have_no_button("Recordar envío de factura")
    end

    within(without_invoice) { click_button "Recordar envío de factura" }

    expect(page).to have_content("Próximo envío disponible en 3 días.", wait: 60)
    expect(page).to have_button("Recordar envío de factura", disabled: true)
  end

  it "avisa en Inicio por la factura faltante y no la repite al cerrarla" do
    InvoiceReminders::MissingNotices.remind!
    period = I18n.l(closed_month.to_date, format: :month_name_year)
    description = "todavía no envió la factura de #{period}"

    visit_hydrated admin_dashboard_path
    without_animations
    open_notifications

    notice = find("[role=alert]", text: description)
    within(notice) { click_button "Cerrar notificación" }
    expect(page).to have_no_content(description, wait: 60)

    InvoiceReminders::MissingNotices.remind!
    visit_hydrated admin_dashboard_path
    without_animations
    open_notifications

    expect(page).to have_no_content(description)
  end

  it "le deja al proveedor la notificación del recordatorio de factura" do
    visit_hydrated admin_payments_path
    without_animations
    within(card_for("$500")) { click_button "Recordar envío de factura" }
    expect(page).to have_content("Próximo envío disponible en 3 días.", wait: 60)

    sign_out
    sign_in users(:provider_user), role: :provider
    visit_hydrated provider_dashboard_path
    without_animations

    expect(page).to have_content("Recordatorio de factura")
    expect(page).to have_content("te recuerda enviar la factura")
  end
end
