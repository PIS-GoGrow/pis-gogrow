# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::Update do
  fixtures :users, :providers, :consumers, :companies

  # Miércoles: la fecha máxima de publicación es el viernes 18.
  before { travel_to Date.new(2030, 1, 9) }

  let(:wednesday) { Date.new(2030, 1, 9) }
  let(:thursday) { Date.new(2030, 1, 10) }
  let(:friday) { Date.new(2030, 1, 11) }
  let(:next_monday) { Date.new(2030, 1, 14) }

  let(:menu) do
    providers(:tuviandita).menus.create!(
      name: "Milanesa", description: "Con papas", price: 300,
      option_groups_attributes: [ { name: "Guarnición", options: [ "Papas", "Puré" ], limit: 1 } ]
    )
  end

  let(:attributes) do
    { name: "Milanesa napolitana", description: "Con jamón y queso", price: "350",
      option_groups_attributes: [ { name: "Guarnición", options: [ "Papas" ], limit: 1 } ] }
  end

  def order_for(schedule, status: :confirmed)
    Order.reserve(consumer: consumers(:one), schedule:, delivery_method: :office, address: nil).tap do |order|
      order.update!(status:)
    end
  end

  def update(agenda, **options)
    described_class.new(menu:, attributes:, agenda:, **options).tap(&:call)
  end

  it "only changes the programmed day when asked for that day" do
    today = menu.schedules.create!(date: wednesday, amount: 5)
    tomorrow = menu.schedules.create!(date: thursday, amount: 5)

    update({ mode: "single", date: thursday.iso8601, amount: 5 }, scope: "day")

    expect(today.reload.menu.name).to eq("Milanesa")
    expect(tomorrow.reload.menu.name).to eq("Milanesa napolitana")
    expect(tomorrow.menu.option_groups.first.options).to eq([ "Papas" ])
    expect(menu.reload.name).to eq("Milanesa")
  end

  it "changes the saved dish from that day on and keeps the earlier days as they were" do
    today = menu.schedules.create!(date: wednesday, amount: 5)
    tomorrow = menu.schedules.create!(date: thursday, amount: 5)

    update({ mode: "single", date: thursday.iso8601, amount: 5 }, scope: "saved")

    expect(menu.reload.name).to eq("Milanesa napolitana")
    expect(tomorrow.reload.menu).to eq(menu)
    expect(today.reload.menu.name).to eq("Milanesa")
    expect(today.menu.base_menu).to eq(menu)
  end

  it "programs a single day that was not programmed" do
    update({ mode: "single", date: friday.iso8601, amount: 4 }, scope: "day")

    schedule = Schedule.find_by(menu_id: menu.family_ids, date: friday)
    expect(schedule.amount).to eq(4)
    expect(schedule.menu.name).to eq("Milanesa napolitana")
  end

  it "applies a weekly agenda from its start and programs it" do
    update({ mode: "weekly", weekdays: [ "1", "5" ], starts_on: wednesday.iso8601, amount: 6 })

    expect(menu.reload.name).to eq("Milanesa napolitana")
    expect(menu.current_agenda.weekdays).to eq([ 1, 5 ])
    expect(Schedule.where(menu_id: menu.family_ids).order(:date).pluck(:date))
      .to eq([ friday, next_monday, Date.new(2030, 1, 18) ])
  end

  it "applies the changes only during a range and goes back to the saved dish after it" do
    menu.agendas.create!(weekdays: [ 1, 2, 3, 4, 5 ], starts_on: wednesday, amount: 5)
    Menus::AgendaScheduler.call(menu)

    update({ mode: "range", weekdays: [ "4", "5" ], starts_on: thursday.iso8601, ends_on: friday.iso8601, amount: 2 })

    changed = Schedule.where(menu_id: menu.family_ids, date: thursday..friday).map { it.menu.name }
    expect(changed).to eq([ "Milanesa napolitana", "Milanesa napolitana" ])
    expect(Schedule.find_by(menu_id: menu.family_ids, date: next_monday).menu).to eq(menu)
    expect(menu.reload.name).to eq("Milanesa")
  end

  it "keeps the confirmed orders when asked to" do
    order = order_for(menu.schedules.create!(date: thursday, amount: 5))

    update({ mode: "single", date: thursday.iso8601, amount: 5 }, scope: "day", confirmed_orders: "keep")

    expect(order.reload).to be_confirmed
    expect(order.menu_name).to eq("Milanesa")
  end

  it "rejects the confirmed orders of the affected days when asked to" do
    affected = order_for(menu.schedules.create!(date: thursday, amount: 5))
    pending = order_for(Schedule.find_by!(menu: menu, date: thursday), status: :pending)
    other_day = order_for(menu.schedules.create!(date: friday, amount: 5))

    update({ mode: "single", date: thursday.iso8601, amount: 5 }, scope: "day", confirmed_orders: "reject")

    expect(affected.reload).to be_rejected
    expect(affected).to be_rejection_reason_dish_modified
    expect(pending.reload).to be_pending
    expect(other_day.reload).to be_confirmed
  end

  it "does not rewrite what an earlier order shows" do
    order = order_for(menu.schedules.create!(date: wednesday, amount: 5))

    update({ mode: "none" })

    expect(menu.reload.name).to eq("Milanesa napolitana")
    expect(order.reload.menu_name).to eq("Milanesa")
    expect(order.menu_option_groups.first["options"]).to eq([ "Papas", "Puré" ])
  end

  it "removes the agenda when no day is picked" do
    menu.agendas.create!(weekdays: [ 1 ], starts_on: wednesday, amount: 5)

    update({ mode: "none" })

    expect(menu.reload.current_agenda).to be_nil
  end

  it "returns the dish errors and changes nothing when the data is invalid" do
    menu.schedules.create!(date: thursday, amount: 5)
    service = described_class.new(menu:, attributes: attributes.merge(name: ""), agenda: { mode: "single", date: thursday.iso8601, amount: 5 }, scope: "day")

    expect(service.call).to be(false)
    expect(service.errors[:name]).to be_present
    expect(Menu.where(base_menu_id: menu.id)).to be_empty
  end

  it "rejects an agenda without weekdays or with a past start" do
    service = described_class.new(menu:, attributes:, agenda: { mode: "weekly", weekdays: [], starts_on: (wednesday - 1).iso8601, amount: 5 })

    expect(service.call).to be(false)
    expect(service.errors[:agenda].size).to eq(2)
    expect(menu.reload.name).to eq("Milanesa")
  end

  describe "#affected_schedules" do
    it "counts only the programmed days the change reaches" do
      menu.schedules.create!(date: wednesday, amount: 5)
      menu.schedules.create!(date: thursday, amount: 5)
      menu.schedules.create!(date: friday, amount: 5)

      day = described_class.new(menu:, attributes:, agenda: { mode: "single", date: thursday.iso8601 }, scope: "day")
      range = described_class.new(menu:, attributes:, agenda: { mode: "range", starts_on: thursday.iso8601, ends_on: friday.iso8601 })

      expect(day.affected_schedules.pluck(:date)).to eq([ thursday ])
      expect(range.affected_schedules.order(:date).pluck(:date)).to eq([ thursday, friday ])
    end
  end
end
