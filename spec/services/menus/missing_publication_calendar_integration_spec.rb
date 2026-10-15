# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::MissingPublicationDetector do
  fixtures :users, :providers

  it "excluye al proveedor cerrado y conserva al que tiene servicio ese día" do
    travel_to Time.zone.local(2030, 1, 9, 10)
    closed_provider = providers(:tuviandita)
    open_provider = providers(:endulzate)
    closed_provider.closures.create!(starts_on: Date.current, ends_on: Date.current, reason: "Vacaciones")

    detected = described_class.call

    expect(detected).to include(open_provider)
    expect(detected).not_to include(closed_provider)
  end

  it "respeta ambos extremos del cierre y permite servicio fuera del rango" do
    travel_to Time.zone.local(2030, 1, 9, 10)
    provider = providers(:tuviandita)
    provider.closures.create!(starts_on: Date.current, ends_on: Date.current + 1.day, reason: "Vacaciones")

    expect(described_class.call(date: Date.current - 1.day)).to include(provider)
    expect(described_class.call(date: Date.current)).not_to include(provider)
    expect(described_class.call(date: Date.current + 1.day)).not_to include(provider)
    expect(described_class.call(date: Date.current + 2.days)).to include(provider)
  end

  it "no notifica si se configura un cierre después de detectar los proveedores" do
    travel_to Time.zone.local(2030, 1, 9, 10)
    provider = providers(:tuviandita)
    candidates = described_class.call
    provider.closures.create!(starts_on: Date.current, ends_on: Date.current, reason: "Vacaciones")

    Menus::MissingPublicationNotifier.call(providers: candidates)

    expect(provider.user.notifications.where(event: :provider_menu_unpublished)).to be_empty
    expect(providers(:endulzate).user.notifications.where(event: :provider_menu_unpublished).count).to eq(1)
  end
end
