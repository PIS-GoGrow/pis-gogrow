# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification::Registry, type: :model do
  it "tiene textos para cada evento y configuración" do
    # Testeamos que los locales sean consistentes con los eventos y
    # configuraciones definidas

    described_class.events.each_key do |event|
      %w[title description].each do |f|
        expect(I18n.exists?("notifications.#{event}.#{f}")).to be(true), "falta notifications.#{event}.#{f}"
      end
    end
    described_class.configurations.each_key do |key|
      %w[title description].each do |f|
        expect(I18n.exists?("notification_configurations.#{key}.#{f}")).to be(true)
      end
    end
  end

  it "queda sincronizado con la base" do
    expect(Notification::Configuration.sync!).to be_blank
  end
end
