# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::MissingPublicationDetector do
  fixtures :users, :providers, :menus

  let(:provider) { providers(:tuviandita) }
  let(:other_provider) { providers(:endulzate) }
  let(:menu) { menus(:milanesa) }
  let(:other_menu) { menus(:sorrentinos) }
  let(:date) { Date.current }

  before { travel_to Time.zone.local(2030, 1, 9, 9, 0) }

  def detected_provider_ids(on: date)
    described_class.call(date: on).order(:id).ids
  end

  it "includes a provider without schedules on the date" do
    expect(detected_provider_ids).to include(provider.id)
  end

  it "uses Date.current by default" do
    menu.schedules.create!(date:, amount: 10)

    expect(described_class.call).not_to include(provider)
  end

  it "excludes a provider with a schedule on an active menu" do
    menu.schedules.create!(date:, amount: 10)

    expect(detected_provider_ids).not_to include(provider.id)
  end

  it "does not count a schedule from another provider" do
    other_menu.schedules.create!(date:, amount: 10)

    expect(detected_provider_ids).to include(provider.id)
  end

  it "does not count a schedule from an archived menu" do
    menu.schedules.create!(date:, amount: 10)
    menu.update!(archived_at: Time.current)

    expect(detected_provider_ids).to include(provider.id)
  end

  it "counts a recurring publication materialized as a schedule" do
    menu.agendas.create!(weekdays: [ date.cwday ], starts_on: date, amount: 10)
    Menus::AgendaScheduler.call(menu)

    expect(detected_provider_ids).not_to include(provider.id)
  end

  it "counts schedules with zero stock or marked unavailable" do
    menu.schedules.create!(date:, amount: 0)
    other_menu.schedules.create!(date:, amount: 10, available: false)

    expect(detected_provider_ids).not_to include(provider.id)
    expect(detected_provider_ids).not_to include(other_provider.id)
  end

  it "returns no providers on Saturday or Sunday" do
    expect(detected_provider_ids(on: Date.new(2030, 1, 12))).to be_empty
    expect(detected_provider_ids(on: Date.new(2030, 1, 13))).to be_empty
  end

  it "uses the date received as a parameter" do
    menu.schedules.create!(date: date + 1.day, amount: 10)

    expect(detected_provider_ids).to include(provider.id)
    expect(detected_provider_ids(on: date + 1.day)).not_to include(provider.id)
  end

  it "returns consistent results across repeated calls" do
    other_menu.schedules.create!(date:, amount: 10)

    first_call = detected_provider_ids

    expect(detected_provider_ids).to eq(first_call)
    expect(first_call).to include(provider.id)
    expect(first_call).not_to include(other_provider.id)
  end
end
