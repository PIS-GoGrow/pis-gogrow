# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Validación de comprobante de pago en español", type: :system do
  fixtures :users, :consumers, :companies, :providers

  let(:consumer) { consumers(:one) }
  let(:employee) { users(:one) }
  let(:provider) { providers(:tuviandita) }
  let(:closed_month) { Date.current.prev_month.beginning_of_month }
  let(:receipt_file) { Rails.root.join("public/icon.png").to_s }

  before do
    consumer.orders.destroy_all
    consumer.accounts.destroy_all

    travel_to(Time.zone.local(closed_month.year, closed_month.month, 5, 12)) do
      menu = Menu.create!(provider:, name: "Torta de fiambre", description: "Porción", price: 500)
      schedule = Schedule.create!(menu:, date: closed_month + 7, amount: 20)

      Order.create!(
        consumer:, schedule:,
        amount: 1, price: 500, discounted_price: 250,
        delivery_method: :office, status: :confirmed
      )
    end

    sign_in employee, role: :consumer
  end

  it "muestra selector de archivo en español y valida el comprobante requerido sin cerrar el diálogo" do
    visit_hydrated accounts_path
    without_animations

    within(find("[role=tabpanel]")) do
      expect(page).to have_button("Subir comprobante de pago")
      click_on "Subir comprobante de pago"
    end

    expect(page).to have_css("[role=dialog]")

    within(find("[role=dialog]")) do
      expect(page).to have_content("Comprobante")
      expect(page).to have_content("Seleccionar archivo")
      expect(page).to have_content("Sin archivos seleccionados")

      click_on "Subir comprobante de pago"

      expect(page).to have_content("Seleccioná el archivo del comprobante.")

      attach_file("Comprobante", receipt_file)

      expect(page).to have_no_content("Seleccioná el archivo del comprobante.")
      expect(page).to have_content("icon.png")

      click_on "Subir comprobante de pago"
    end

    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_description"))
  end
end
