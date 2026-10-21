# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderEvent, type: :model do
  fixtures :users, :companies, :consumers, :providers, :menus, :schedules, :orders

  let(:order) { orders(:upcoming_pending_future) }

  it "records the creation with the initial values" do
    created = Order.create!(
      consumer: consumers(:one),
      schedule: schedules(:future),
      amount: 2,
      price: 600,
      discounted_price: 300,
      delivery_method: :office
    )

    expect(created.events.sole).to have_attributes(
      action: "created",
      company: companies(:gogrow),
      changeset: a_hash_including("amount" => [ nil, 2 ], "price" => [ nil, "600.0" ], "discounted_price" => [ nil, "300.0" ])
    )
  end

  it "records the actor and the role of the session" do
    Current.session = users(:one).sessions.create!(role: :consumer)

    order.update!(notes: "Sin sal")

    expect(order.events.sole).to have_attributes(
      action: "modified",
      user: users(:one),
      actor_name: users(:one).name,
      role: "consumer",
      changeset: { "notes" => [ nil, "Sin sal" ] }
    )
  end

  it "names a change in the prices alone as an economic change" do
    order.update!(price: 400, discounted_price: 200)

    expect(order.events.sole).to have_attributes(action: "price_changed", user: nil, role: nil)
  end

  it "names a status change after the new status" do
    order.cancel(by: users(:one))

    expect(order.events.sole).to have_attributes(action: "cancelled", changeset: { "status" => %w[pending cancelled] })
  end

  it "does not record saves that only touch bookkeeping columns" do
    order.update!(modified_at: Time.current)

    expect(order.events).to be_empty
  end

  it "does not record a change that fails validation" do
    order.update(amount: 0)

    expect(order.events).to be_empty
  end

  it "cannot be edited or deleted once saved" do
    order.update!(notes: "Sin sal")
    event = order.events.sole

    expect { event.update!(changeset: {}) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { event.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "outlives the order" do
    order.update!(notes: "Sin sal")

    order.destroy!

    expect(described_class.where(order_id: order.id)).to exist
  end
end
