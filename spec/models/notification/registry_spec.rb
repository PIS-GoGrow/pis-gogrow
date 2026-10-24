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

  it "tiene una plantilla de Twilio por cada texto de cada evento" do
    described_class.events.each_value do |event|
      description = I18n.t("notifications.#{event.key}.description")
      expected = description.is_a?(Hash) ? %i[one other] : nil

      expect(event.content_sid.is_a?(Hash) ? event.content_sid.keys.sort : nil).to eq(expected), event.key.to_s
      expect(Array(event.content_sid.try(:values) || event.content_sid)).to all(match(/\AHX\h{32}\z/)), event.key.to_s
    end
  end

  it "queda sincronizado con la base" do
    expect(Notification::Configuration.sync!).to be_blank
  end
end
