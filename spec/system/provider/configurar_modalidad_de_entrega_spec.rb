# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Configurar la modalidad de entrega como proveedor" do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules, :orders

  let(:provider) { providers(:tuviandita) }

  def selected_option
    find("[role=radio][aria-checked=true]")[:id]
  end

  def choose_delivery(title)
    find("label", text: title).click
    expect(page).to have_content(I18n.t("flash.deliveries_updated"))
  end

  it "lets the provider choose office only and saves it" do
    sign_in provider.user, role: :provider
    visit provider_deliveries_path

    expect(selected_option).to eq("delivery-home")

    choose_delivery("Solo Oficinas")

    expect(selected_option).to eq("delivery-office")
    expect(provider.reload.home_delivery).to be(false)
  end

  it "lets the provider turn custom-address delivery back on" do
    provider.update!(home_delivery: false)
    sign_in provider.user, role: :provider
    visit provider_deliveries_path

    expect(selected_option).to eq("delivery-office")

    choose_delivery("Oficinas y direcciones personalizadas")

    expect(selected_option).to eq("delivery-home")
    expect(provider.reload.home_delivery).to be(true)
  end

  it "keeps the setting after signing out and signing in again" do
    sign_in provider.user, role: :provider
    visit provider_deliveries_path
    choose_delivery("Solo Oficinas")

    sign_out
    visit provider_deliveries_path
    expect(page).to have_current_path(provider_sign_in_path)

    sign_in provider.user, role: :provider
    visit provider_deliveries_path

    expect(selected_option).to eq("delivery-office")
    expect(provider.reload.home_delivery).to be(false)
  end

  it "does not touch another provider's setting" do
    other_provider = providers(:endulzate)
    sign_in provider.user, role: :provider
    visit provider_deliveries_path

    choose_delivery("Solo Oficinas")

    expect(provider.reload.home_delivery).to be(false)
    expect(other_provider.reload.home_delivery).to be(true)
  end

  it "keeps published menus and orders when custom-address delivery is disabled" do
    schedule = schedules(:future)
    order = orders(:upcoming_pending_future)
    sign_in provider.user, role: :provider
    visit provider_deliveries_path

    choose_delivery("Solo Oficinas")

    expect(schedule.reload).to have_attributes(menu: menus(:milanesa))
    expect(order.reload).to have_attributes(delivery_method: "home", address: "Julio Herrera y Reissig 565")
  end

  it "does not expose delivery settings in the profile" do
    sign_in provider.user, role: :provider

    visit settings_profile_path

    expect(page).to have_current_path(settings_profile_path)
    expect(page).to have_no_selector("#home_delivery")
    expect(page).to have_no_content(I18n.t("pages.settings.profile.home_delivery.heading"))
    expect(page).to have_no_content(I18n.t("pages.settings.profile.home_delivery.label"))
  end
end
