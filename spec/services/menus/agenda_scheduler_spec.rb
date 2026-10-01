# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::AgendaScheduler do
  fixtures :users, :providers

  # Miércoles: la fecha máxima de publicación es el viernes 18.
  before { travel_to Date.new(2030, 1, 9) }

  let(:menu) do
    providers(:tuviandita).menus.create!(name: "Sorrentinos", description: "Con salsa", price: 300)
  end

  def scheduled_dates(menu)
    Schedule.where(menu_id: menu.family_ids).order(:date).pluck(:date)
  end

  it "programs the agenda weekdays up to the maximum publish date" do
    menu.agendas.create!(weekdays: [ 1, 3 ], starts_on: Date.current, amount: 8)

    described_class.call(menu)

    expect(scheduled_dates(menu)).to eq([ Date.new(2030, 1, 9), Date.new(2030, 1, 14), Date.new(2030, 1, 16) ])
    expect(menu.schedules.pluck(:amount).uniq).to eq([ 8 ])
  end

  it "does not program twice the same date" do
    menu.agendas.create!(weekdays: [ 3 ], starts_on: Date.current, amount: 8)
    menu.schedules.create!(date: Date.current, amount: 2)

    2.times { described_class.call(menu) }

    expect(scheduled_dates(menu)).to eq([ Date.new(2030, 1, 9), Date.new(2030, 1, 16) ])
    expect(menu.schedules.find_by(date: Date.current).amount).to eq(2)
  end

  it "uses the agenda of a ranged variant during its range and the saved dish after it" do
    menu.agendas.create!(weekdays: [ 1, 2, 3, 4, 5 ], starts_on: Date.current, amount: 5)
    variant = menu.build_variant(valid_from: Date.new(2030, 1, 14), valid_until: Date.new(2030, 1, 15))
    variant.name = "Sorrentinos de verdura"
    variant.agendas.build(weekdays: [ 2 ], starts_on: Date.new(2030, 1, 14), ends_on: Date.new(2030, 1, 15), amount: 3)
    variant.save!

    described_class.call(menu)

    expect(variant.schedules.pluck(:date)).to eq([ Date.new(2030, 1, 15) ])
    expect(menu.schedules.pluck(:date)).not_to include(Date.new(2030, 1, 14), Date.new(2030, 1, 15))
    expect(menu.schedules.pluck(:date)).to include(Date.new(2030, 1, 16))
  end

  it "programs a plain variant on the dates it covers" do
    menu.agendas.create!(weekdays: [ 4, 5 ], starts_on: Date.current, amount: 5)
    variant = menu.build_variant(valid_from: Date.new(2030, 1, 10), valid_until: Date.new(2030, 1, 10))
    variant.save!

    described_class.call(menu)

    expect(variant.schedules.pluck(:date)).to eq([ Date.new(2030, 1, 10) ])
  end

  it "stops at the end of a finished agenda" do
    menu.agendas.create!(weekdays: [ 1, 2, 3, 4, 5 ], starts_on: Date.current, ends_on: Date.new(2030, 1, 10), amount: 5)

    described_class.call(menu)

    expect(scheduled_dates(menu)).to eq([ Date.new(2030, 1, 9), Date.new(2030, 1, 10) ])
  end
end
