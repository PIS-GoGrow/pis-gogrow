# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Comprobante en revisión en pagos de empresa", type: :system do
  fixtures :users, :companies, :admins, :providers

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
    account
  end

  it "muestra el botón deshabilitado con leyenda cuando hay un comprobante en revisión y se habilita al rechazarlo" do
    sign_in admin_user, role: :admin
    visit admin_payments_path

    within(find("[data-slot=card]", text: provider_user.name)) do
      expect(page).to have_button(I18n.t("pages.accounts.show.receipt"), disabled: false)
    end

    payment = account.payments.build(provider:, status: :submitted)
    payment.receipt.attach(io: File.open(receipt_file), filename: "comprobante.png", content_type: "image/png")
    payment.save!

    visit admin_payments_path

    within(find("[data-slot=card]", text: provider_user.name)) do
      expect(page).to have_button(I18n.t("pages.accounts.show.receipt"), disabled: true)
      expect(page).to have_content(I18n.t("pages.accounts.show.receipt_under_review_hint"))
    end

    payment.reject_with("Comprobante ilegible")
    visit admin_payments_path

    within(find("[data-slot=card]", text: provider_user.name)) do
      expect(page).to have_button(I18n.t("pages.accounts.show.receipt"), disabled: false)
      expect(page).to have_no_content(I18n.t("pages.accounts.show.receipt_under_review_hint"))
    end
  end
end
