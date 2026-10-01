# frozen_string_literal: true

require "rails_helper"

RSpec.describe MenuAgenda, type: :model do
  fixtures :users, :providers

  let(:menu) { providers(:tuviandita).menus.create!(name: "Tarta", description: "De jamón", price: 250) }

  it "is valid with working weekdays, a start and a stock" do
    expect(menu.agendas.build(weekdays: [ 1, 5 ], starts_on: Date.current, amount: 3)).to be_valid
  end

  it "rejects weekends and empty weekdays" do
    expect(menu.agendas.build(weekdays: [ 6 ], starts_on: Date.current, amount: 3)).not_to be_valid
    expect(menu.agendas.build(weekdays: [], starts_on: Date.current, amount: 3)).not_to be_valid
  end

  it "requires a positive stock" do
    expect(menu.agendas.build(weekdays: [ 1 ], starts_on: Date.current, amount: 0)).not_to be_valid
  end

  it "does not end before it starts" do
    agenda = menu.agendas.build(weekdays: [ 1 ], starts_on: Date.current, ends_on: Date.current - 1, amount: 3)

    expect(agenda).not_to be_valid
  end
end
