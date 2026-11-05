# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bloqueo de comprobante mientras el proveedor no cargue datos de cobro", type: :system do
  fixtures :users, :companies, :admins, :providers, :accounts

  let(:company) { companies(:gogrow) }
  let(:admin_user) { users(:admin) }
  let(:provider_without_details) { providers(:tuviandita) }
  let(:provider_with_details) { providers(:endulzate) }
  let(:tuviandita_account) { accounts(:gogrow_tuviandita_current) }
  let(:endulzate_account) do
    Account.create!(
      owner: company,
      provider: provider_with_details,
      month: Date.current.beginning_of_month,
      amount: 2500
    )
  end

  before do
    provider_without_details.update!(
      bank_name: nil,
      bank_account_details: nil,
      beneficiary: nil
    )
    provider_with_details.update!(
      bank_name: "Banco Itaú",
      bank_account_details: "1951234",
      beneficiary: "Noelia Patricia Pinheiro"
    )
    tuviandita_account
    endulzate_account
  end

  def card_for(provider)
    find("[data-slot=card-title]", exact_text: provider.user.name).ancestor("[data-slot=card]")
  end

  it "deshabilita el botón con advertencia y leyenda explicativa, y se habilita tras cargar datos" do
    sign_in admin_user, role: :admin
    visit admin_payments_path

    # Proveedor sin datos de cobro
    within(card_for(provider_without_details)) do
      expect(page).to have_content(I18n.t("pages.admin.payments.index.bank.missing"))
      expect(page).to have_button(I18n.t("pages.accounts.show.receipt"), disabled: true)
      expect(page).to have_content(I18n.t("pages.admin.payments.index.bank.missing_upload_hint"))
    end

    # Proveedor con datos de cobro completos
    within(card_for(provider_with_details)) do
      expect(page).to have_content("Banco Itaú")
      expect(page).to have_content("1951234")
      expect(page).to have_button(I18n.t("pages.accounts.show.receipt"), disabled: false)
      expect(page).to have_no_content(I18n.t("pages.admin.payments.index.bank.missing_upload_hint"))
    end

    # Cargar datos de cobro del proveedor
    provider_without_details.update!(
      bank_name: "Santander",
      bank_account_details: "1150260",
      beneficiary: "Tu Viandita S.A."
    )

    visit admin_payments_path

    within(card_for(provider_without_details)) do
      expect(page).to have_no_content(I18n.t("pages.admin.payments.index.bank.missing"))
      expect(page).to have_content("Santander")
      expect(page).to have_content("1150260")
      expect(page).to have_button(I18n.t("pages.accounts.show.receipt"), disabled: false)
      expect(page).to have_no_content(I18n.t("pages.admin.payments.index.bank.missing_upload_hint"))
    end
  end
end
