# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notificaciones al proveedor durante cierres programados", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :menu_option_groups, :schedules, :orders, :accounts

  let(:consumer_user) { users(:one) }
  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }
  let(:account) { accounts(:one_tuviandita_current) }
  let(:order_cancellation_title) { "Un pedido fue cancelado" }
  let(:payment_receipt_title) { "Nuevo comprobante de pago" }

  def receipt_file
    Rails.root.join("public/icon.png").to_s
  end

  before do
    page.current_window.resize_to(1400, 1400)
    provider.closures.destroy_all
    Payment.where(account:).destroy_all
    account.update!(month: Date.current.prev_month.beginning_of_month)
  end

  context "cuando el proveedor se encuentra cerrado en la fecha actual" do
    before do
      provider.closures.create!(
        starts_on: Date.current,
        ends_on: Date.current + 2.days,
        reason: "Cierre programado"
      )
    end

    it "no genera notificación cuando el consumidor cancela un pedido confirmado" do
      order = orders(:upcoming_confirmed_future)

      sign_in consumer_user, role: :consumer
      visit_hydrated order_path(order)
      without_animations
      click_button "Cancelar"
      within("[role=dialog]") { click_button "Cancelar pedido" }
      expect(page).to have_content("Pedido cancelado")
      sign_out

      sign_in provider_user, role: :provider
      visit_hydrated provider_dashboard_path

      expect(page).to have_content("Hola,")
      expect(page).to have_no_content(order_cancellation_title)
    end

    it "no genera notificación cuando el consumidor envía un comprobante de pago" do
      sign_in consumer_user, role: :consumer
      visit_hydrated accounts_path

      within(find("[role=tabpanel]")) do
        attach_file(I18n.t("pages.accounts.show.receipt_file"), receipt_file)
        click_on I18n.t("pages.accounts.show.receipt")
      end

      expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_title"))
      click_on I18n.t("pages.accounts.show.receipt_success_action")
      sign_out

      sign_in provider_user, role: :provider
      visit_hydrated provider_dashboard_path

      expect(page).to have_content("Hola,")
      expect(page).to have_no_content(payment_receipt_title)
    end
  end

  context "cuando el proveedor se encuentra abierto" do
    it "notifica al proveedor al cancelar un pedido confirmado" do
      order = orders(:upcoming_confirmed_future)

      sign_in consumer_user, role: :consumer
      visit_hydrated order_path(order)
      without_animations
      click_button "Cancelar"
      within("[role=dialog]") { click_button "Cancelar pedido" }
      expect(page).to have_content("Pedido cancelado")
      sign_out

      sign_in provider_user, role: :provider
      visit_hydrated provider_dashboard_path

      expect(page).to have_content(order_cancellation_title)
      expect(page).to have_content(
        "El pedido de #{consumer_user.name} del #{DateFormat.long(order.schedule.date, inline: true)} de #{order.menu_name} fue cancelado."
      )
    end

    it "notifica al proveedor al enviar un comprobante de pago" do
      sign_in consumer_user, role: :consumer
      visit_hydrated accounts_path

      within(find("[role=tabpanel]")) do
        attach_file(I18n.t("pages.accounts.show.receipt_file"), receipt_file)

        expect(page).to have_button(
          I18n.t("pages.accounts.show.receipt"),
          disabled: false
        )

        click_on I18n.t("pages.accounts.show.receipt")
      end

      expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_title"))
      click_on I18n.t("pages.accounts.show.receipt_success_action")
      sign_out

      sign_in provider_user, role: :provider
      visit_hydrated provider_dashboard_path

      expect(page).to have_content(payment_receipt_title)
      expect(page).to have_content("#{consumer_user.name} envió un comprobante de pago")
    end
  end
end
