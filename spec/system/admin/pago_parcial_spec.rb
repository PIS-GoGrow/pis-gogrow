# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Visualización y gestión de pago parcial por RR. HH.", type: :system do
  fixtures :users, :companies, :admins, :providers, :consumers, :accounts

  let(:company) { companies(:gogrow) }
  let(:admin_user) { users(:admin) }
  let(:provider) { providers(:endulzate) }
  let(:provider_user) { provider.user }
  let(:account) do
    Account.create!(
      owner: company,
      provider:,
      month: Date.current.beginning_of_month - 2.months,
      amount: 4500
    )
  end

  def receipt_file
    Rails.root.join("public/icon.png").to_s
  end

  before do
    provider.update!(
      bank_name: "Banco Itaú",
      bank_account_details: "1951234",
      beneficiary: "Noelia Patricia Pinheiro"
    )
    account
  end

  it "permite subir un nuevo comprobante tras un pago parcial y mantiene la cuenta pendiente" do
    payment = account.payments.build(provider:, status: :submitted)
    payment.receipt.attach(io: File.open(receipt_file), filename: "comprobante_1.png", content_type: "image/png")
    payment.save!

    payment.mark_partial

    sign_in admin_user, role: :admin
    visit_hydrated admin_payments_path

    within(find("[data-slot=card]", text: provider_user.name)) do
      expect(page).to have_field(I18n.t("pages.accounts.show.receipt_file"), disabled: false)
      attach_file(I18n.t("pages.accounts.show.receipt_file"), receipt_file)
      expect(page).to have_button(I18n.t("pages.accounts.show.receipt"), disabled: false)
      expect(page).to have_no_content(I18n.t("pages.accounts.show.receipt_under_review_hint"))
    end

    expect(Account.pending).to include(account.reload)
    expect(account.collection_status).to eq("partial")
  end
end
