# frozen_string_literal: true

# Historia IBP-045: "Como RR.HH., quiero recibir una notificación cuando se
# aproxime o se registre un pago de GoGrow a un proveedor, para no omitir la
# transferencia correspondiente."
#
# La parte de "se registre un pago": RR.HH. sube el comprobante del pago de la
# empresa y el proveedor lo revisa. El resultado de esa revisión le llega a
# RR.HH. como aviso en su inicio.

require "rails_helper"

RSpec.describe "Notificación del estado de un pago a proveedor", type: :system do
  fixtures :users, :companies, :admins, :providers

  let(:company) { companies(:gogrow) }
  let(:admin_user) { users(:admin) }
  let(:provider) { providers(:endulzate) }
  let(:provider_user) { provider.user }
  let(:approved_title) { I18n.t("notifications.company_payment_approved.title") }
  let(:rejected_title) { I18n.t("notifications.company_payment_rejected.title") }

  # Período cerrado con deuda: es el que RR.HH. paga y el proveedor revisa.
  let(:account) do
    Account.create!(
      owner: company,
      provider:,
      month: Date.current.beginning_of_month - 2.months,
      amount: 4500
    )
  end

  before do
    Notification::Configuration.find_or_create_by!(key: "company_payments") do |configuration|
      configuration.roles = %w[admin]
    end
  end

  def receipt_file
    Rails.root.join("public/icon.png").to_s
  end

  def month_name
    I18n.l(account.month, format: :month_name_year)
  end

  # RR.HH. sube el comprobante del pago de la empresa desde Pagos.
  def hr_uploads_receipt
    sign_in admin_user, role: :admin
    visit admin_payments_path

    within(find("[data-slot=card]", text: provider_user.name)) do
      click_on "Subir comprobante de pago"
    end

    within(find("[role=dialog]")) do
      attach_file("Seleccionar archivo", receipt_file)
      click_on "Subir comprobante de pago"
    end

    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_description"))
    click_on I18n.t("pages.accounts.show.receipt_success_action")
  end

  # El proveedor revisa el comprobante de la empresa del período.
  def provider_reviews(decision)
    sign_in provider_user, role: :provider
    visit provider_collections_path

    within(find("[data-slot=card]", text: month_name)) { click_on "Empresa" }
    click_on "Revisar pago"

    if decision == :approve
      within(find("[role=dialog]")) { click_on "Aprobar" }
      expect(page).to have_content(I18n.t("pages.provider_collections.review.approved_title"))
    else
      within(find("[role=dialog]")) { click_on "Rechazar" }
      within(find("[role=dialog]", text: "Rechazar comprobante")) do
        choose "Otro"
        fill_in "Motivo", with: "El importe no coincide"
        click_on "Rechazar comprobante"
      end
      expect(page).to have_content(I18n.t("pages.provider_collections.review.rejected_title"))
    end

    click_on I18n.t("pages.provider_collections.review.done")
  end

  def open_admin_home
    sign_in admin_user, role: :admin
    visit admin_dashboard_path
  end

  it "avisa a RR.HH. cuando el proveedor confirma el pago de la empresa" do
    account
    hr_uploads_receipt
    sign_out

    provider_reviews(:approve)
    sign_out

    open_admin_home

    expect(page).to have_content(approved_title)
    expect(page).to have_content(
      "#{provider_user.name} confirmó el pago de GoGrow por " \
        "#{I18n.l(account.month, format: :month_name_year).downcase} (#{account.formatted_amount})."
    )
  end

  it "avisa a RR.HH. cuando el proveedor rechaza el comprobante y no deja descartarlo" do
    account
    hr_uploads_receipt
    sign_out

    provider_reviews(:reject)
    sign_out

    open_admin_home

    expect(page).to have_content(rejected_title)
    expect(page).to have_content(
      "El comprobante que subiste fue rechazado por #{provider_user.name}. " \
        "Volvé a cargarlo para confirmar tu pago."
    )
    # Requiere acción (volver a subir el comprobante): no se puede cerrar.
    expect(page).to have_no_button("Cerrar notificación")
  end
end
