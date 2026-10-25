# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Subida de varios comprobantes y eliminación por el empleado", type: :system do
  fixtures :users, :consumers, :companies, :providers, :accounts

  def receipt_file
    Rails.root.join("public/icon.png").to_s
  end

  def employee
    users(:one)
  end

  let(:account) { accounts(:one_tuviandita_current) }

  before do
    # Dejamos solo la cuenta de tuviandita para consumers(:one) y sin pagos previos
    consumers(:one).accounts.where.not(id: account.id).destroy_all
    Payment.where(account:).destroy_all
    account.update!(month: Date.current.prev_month.beginning_of_month)
  end

  it "no deja subir comprobantes de la cuenta del mes en curso" do
    account.update!(month: Date.current.beginning_of_month)
    sign_in employee

    visit accounts_path

    within(find("[role=tabpanel]")) do
      expect(page).to have_content(account.amount.to_i.to_s)
      expect(page).to have_no_button(I18n.t("pages.accounts.show.receipt"))
    end
  end

  it "permite subir un comprobante a la vez para la misma cuenta y volver a subir uno si se elimina el que está en revisión" do
    sign_in employee

    visit accounts_path

    # 1. Subir el primer comprobante
    within(find("[role=tabpanel]")) do
      expect(page).to have_button(I18n.t("pages.accounts.show.receipt"))
      click_on I18n.t("pages.accounts.show.receipt")
    end

    within(find("[role=dialog]")) do
      attach_file(I18n.t("pages.accounts.show.receipt_file"), receipt_file)
      click_on I18n.t("pages.accounts.show.receipt")
    end

    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_title"))
    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_description"))
    click_on I18n.t("pages.accounts.show.receipt_success_action")

    within(find("[role=tabpanel]")) do
      expect(page).to have_content("En revisión")
      expect(page).to have_content("icon.png")
      expect(page).to have_button(I18n.t("pages.accounts.show.receipt_remove"))
    end

    # 2. Con un comprobante en revisión el botón queda deshabilitado
    within(find("[role=tabpanel]")) do
      expect(page).to have_button(I18n.t("pages.accounts.show.receipt"), disabled: true)
      expect(page).to have_content(I18n.t("pages.accounts.show.receipt_under_review_hint"))
    end

    # 3. Eliminar el comprobante en revisión
    within(find("[role=tabpanel]")) do
      first(:button, I18n.t("pages.accounts.show.receipt_remove")).click
    end

    within(find("[role=dialog]")) do
      click_on I18n.t("pages.accounts.show.receipt_remove_confirm")
    end

    expect(page).to have_content(I18n.t("flash.payment_receipt_removed"))

    # 4. Sin nada en revisión se puede volver a subir
    within(find("[role=tabpanel]")) do
      expect(page).to have_no_button(I18n.t("pages.accounts.show.receipt_remove"))
      expect(page).to have_button(I18n.t("pages.accounts.show.receipt"), disabled: false)
    end
  end

  it "vuelve a habilitar el botón de subida cuando el comprobante en revisión es rechazado" do
    payment = account.payments.build(provider: account.provider, status: :submitted)
    payment.receipt.attach(io: File.open(receipt_file), filename: "icon.png", content_type: "image/png")
    payment.save!

    sign_in employee
    visit accounts_path

    within(find("[role=tabpanel]")) do
      expect(page).to have_button(I18n.t("pages.accounts.show.receipt"), disabled: true)
      expect(page).to have_content(I18n.t("pages.accounts.show.receipt_under_review_hint"))
    end

    payment.reject_with("Comprobante ilegible")

    visit accounts_path

    within(find("[role=tabpanel]")) do
      expect(page).to have_content("Rechazado")
      expect(page).to have_button(I18n.t("pages.accounts.show.receipt"), disabled: false)
      expect(page).to have_no_content(I18n.t("pages.accounts.show.receipt_under_review_hint"))
    end
  end
end
