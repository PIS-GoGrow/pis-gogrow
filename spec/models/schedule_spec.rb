# frozen_string_literal: true

require "rails_helper"

RSpec.describe Schedule, type: :model do
  fixtures :users

  let(:provider) { Provider.create!(user: users(:one)) }

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

  it "allows an amount equal to the maximum limit" do
    schedule = described_class.new(
      date: Date.current,
      amount: described_class::MAX_AMOUNT,
      menu: menu
    )

    expect(schedule).to be_valid
  end

  it "does not allow an amount greater than the maximum limit" do
    schedule = described_class.new(
      date: Date.current,
      amount: described_class::MAX_AMOUNT + 1,
      menu: menu
    )

    expect(schedule).not_to be_valid
    expect(schedule.errors[:amount]).to include(
      I18n.t("errors.messages.less_than_or_equal_to", count: described_class::MAX_AMOUNT)
    )
  end

  it "does not allow a non-integer amount" do
    schedule = described_class.new(
      date: Date.current,
      amount: 10.5,
      menu: menu
    )

    expect(schedule).not_to be_valid
    expect(schedule.errors[:amount]).to include(
      I18n.t("errors.messages.not_an_integer")
    )
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

  describe "#order_deadline_passed?" do
    let(:today) { Date.new(2026, 9, 14) }
    let(:schedule) { described_class.create!(date: today, amount: 10, menu: menu) }

    def at(hour, min, sec = 0, &)
      travel_to(Time.zone.local(today.year, today.month, today.day, hour, min, sec), &)
    end

    before { provider.update!(order_deadline: "12:00") }

    it "is false one second before the deadline" do
      at(11, 59, 59) do
        expect(schedule.order_deadline_passed?).to be false
        expect(schedule).to be_available
      end
    end

    it "is true exactly at the deadline" do
      at(12, 0) do
        expect(schedule.order_deadline_passed?).to be true
        expect(schedule).not_to be_available
      end
    end

    it "is true after the deadline" do
      at(18, 0) { expect(schedule.order_deadline_passed?).to be true }
    end

    it "does not close a schedule for another day" do
      tomorrow = described_class.create!(date: today + 1, amount: 10, menu: menu)

      at(18, 0) do
        expect(tomorrow.order_deadline_passed?).to be false
        expect(tomorrow).to be_available
      end
    end

    it "is false when the provider has no deadline" do
      provider.update!(order_deadline: nil)

      at(23, 59) { expect(schedule.order_deadline_passed?).to be false }
    end

    it "follows a deadline changed after the schedule was loaded" do
      at(11, 0) do
        expect(schedule.order_deadline_passed?).to be false

        provider.update!(order_deadline: "10:30")

        expect(schedule.reload.order_deadline_passed?).to be true
      end
    end
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
