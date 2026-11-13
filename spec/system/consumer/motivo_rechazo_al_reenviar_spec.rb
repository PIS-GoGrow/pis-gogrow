# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Conservar el motivo de rechazo al reenviar un comprobante", type: :system do
  fixtures :users, :consumers, :companies, :providers, :accounts

  def receipt_file
    Rails.root.join("public/icon.png").to_s
  end

  def employee
    users(:one)
  end

  let(:account) { accounts(:one_tuviandita_current) }
  let(:provider) { providers(:tuviandita) }

  before do
    provider.update!(
      bank_name: "Santander",
      bank_account_details: "Cuenta: 1150260\nMoneda: UYU",
      beneficiary: "Tu Viandita S.A."
    )
    consumers(:one).accounts.where.not(id: account.id).destroy_all
    Payment.where(account:).destroy_all
    account.update!(month: Date.current.prev_month.beginning_of_month)
  end

  it "muestra el motivo del rechazo anterior mientras hay un nuevo comprobante en revisión" do
    rejected_payment = account.payments.create!(
      provider:,
      status: :rejected,
      rejection_reason: "Comprobante ilegible o cortado"
    )
    rejected_payment.receipt.attach(
      io: File.open(receipt_file),
      filename: "comprobante_anterior.png",
      content_type: "image/png"
    )

    sign_in employee
    visit_hydrated accounts_path

    within(find("[role=tabpanel]")) do
      expect(page).to have_content("Comprobante ilegible o cortado")
      expect(page).to have_content(I18n.t("pages.accounts.show.status_rejected"))
      expect(page).to have_button(I18n.t("pages.accounts.show.receipt"), disabled: true)

      attach_file(I18n.t("pages.accounts.show.receipt_file"), receipt_file)
      click_on I18n.t("pages.accounts.show.receipt")
    end

    expect(page).to have_content(I18n.t("pages.accounts.show.receipt_success_title"))
    click_on I18n.t("pages.accounts.show.receipt_success_action")

    within(find("[role=tabpanel]")) do
      expect(page).to have_content("En revisión")
      expect(page).to have_content("Comprobante ilegible o cortado")
      expect(page).to have_content(I18n.t("pages.accounts.show.status_rejected"))
    end

    expect(account.payments.count).to eq(2)
    expect(rejected_payment.reload).to be_rejected
    expect(rejected_payment.rejection_reason).to eq("Comprobante ilegible o cortado")
    new_payment = account.payments.where.not(id: rejected_payment.id).sole
    expect(new_payment).to be_submitted
    expect(new_payment.rejection_reason).to be_nil

    # 6. Al aprobarse el pago, la cuenta pasa al Historial y ya no muestra el aviso de rechazo
    new_payment.approve
    visit_hydrated accounts_path

    expect(page).to have_no_content("Comprobante ilegible o cortado")
    find("[role=tab]", text: "Historial").click
    expect(page).to have_content("Confirmado")
  end
end
