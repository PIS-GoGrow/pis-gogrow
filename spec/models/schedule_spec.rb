# frozen_string_literal: true

require "rails_helper"

RSpec.describe Schedule, type: :model do
  let(:provider) { Provider.create! }

  let(:menu) do
    Menu.create!(
      name: "Milanesa con puré",
      description: "Milanesa acompañada de puré",
      price: 350,
      provider: provider
    )
  end

  it "is valid with a date, non-negative amount and menu" do
    schedule = described_class.new(
      date: Date.current,
      amount: 10,
      menu: menu
    )

    expect(schedule).to be_valid
  end

  it "requires a date" do
    schedule = described_class.new(
      date: nil,
      amount: 10,
      menu: menu
    )

    expect(schedule).not_to be_valid
  end

  it "does not allow a negative amount" do
    schedule = described_class.new(
      date: Date.current,
      amount: -1,
      menu: menu
    )

    expect(schedule).not_to be_valid
  end

  it "allows zero amount" do
    schedule = described_class.new(
      date: Date.current,
      amount: 0,
      menu: menu
    )

    expect(schedule).to be_valid
  end

  it "does not allow the same menu twice on the same date" do
    described_class.create!(
      date: Date.current,
      amount: 10,
      menu: menu
    )

    duplicate = described_class.new(
      date: Date.current,
      amount: 5,
      menu: menu
    )

    expect(duplicate).not_to be_valid
  end

  it "allows the same menu on different dates" do
    described_class.create!(
      date: Date.current,
      amount: 10,
      menu: menu
    )

    another_day = described_class.new(
      date: Date.current + 1.day,
      amount: 5,
      menu: menu
    )

    expect(another_day).to be_valid
  end
end



# == Schema Information
#
# Table name: schedules
#
#  id         :bigint           not null, primary key
#  amount     :integer          not null
#  date       :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  menu_id    :bigint           not null
#
# Indexes
#
#  index_schedules_on_menu_id           (menu_id)
#  index_schedules_on_menu_id_and_date  (menu_id,date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (menu_id => menus.id)
#
