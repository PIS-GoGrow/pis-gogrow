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
      changeset: a_hash_including("status" => [ nil, "pending" ], "amount" => [ nil, 2 ], "price" => [ nil, "600.0" ], "discounted_price" => [ nil, "300.0" ])
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

  # IBP-038 CA1: la creación queda a nombre del empleado que pidió.
  it "records the creation under the employee who placed the order" do
    Current.session = users(:one).sessions.create!(role: :consumer)

    created = Order.create!(consumer: consumers(:one), schedule: schedules(:future), amount: 1, price: 300, delivery_method: :office)

    expect(created.events.sole).to have_attributes(action: "created", user: users(:one), role: "consumer")
  end

  # IBP-038 CA3: una disputa "pedí 1, no 2" se resuelve con la cantidad y los
  # dos precios, anteriores y nuevos, en el mismo evento.
  it "records an employee's modification with the quantity and both prices before and after" do
    Current.session = users(:one).sessions.create!(role: :consumer)

    expect(order.modify(by: users(:one), quantity: 2, notes: nil, delivery: { delivery_method: "home", address: order.address })).to eq(order)

    event = order.events.sole
    expect(event).to have_attributes(action: "modified", user: users(:one), role: "consumer")
    expect(event.changeset["amount"]).to eq([ 1, 2 ])
    expect(event.changeset["price"].map(&:to_d)).to eq([ 300.5.to_d, order.price ])
    expect(event.changeset["discounted_price"].map(&:to_d)).to eq([ 150.25.to_d, order.discounted_price ])
  end

  # IBP-038 CA3, eje quién dispara: lo que hace el proveedor no queda a nombre
  # del empleado dueño del pedido.
  it "records a provider's rejection under the provider, with the reason" do
    Current.session = users(:provider_user).sessions.create!(role: :provider)

    order.decide(:rejected, reason: :out_of_stock, details: "Sin pan", by: users(:provider_user))

    expect(order.events.sole).to have_attributes(
      action: "rejected",
      user: users(:provider_user),
      role: "provider",
      changeset: a_hash_including("status" => %w[pending rejected], "rejection_reason" => [ nil, "out_of_stock" ], "rejection_details" => [ nil, "Sin pan" ])
    )
  end

  it "records the rejection caused by a dish change under the provider" do
    Current.session = users(:provider_user).sessions.create!(role: :provider)

    order.reject_for_dish_change!(reason: :dish_unpublished, by: users(:provider_user))

    expect(order.events.sole).to have_attributes(action: "rejected", user: users(:provider_user), role: "provider")
  end

  it "outlives the order" do
    order.update!(notes: "Sin sal")

    order.destroy!

    expect(described_class.where(order_id: order.id)).to exist
  end
end

# == Schema Information
#
# Table name: order_events
#
#  id         :bigint           not null, primary key
#  action     :integer          not null
#  actor_name :string
#  changeset  :jsonb            not null
#  role       :integer
#  created_at :datetime         not null
#  company_id :bigint           not null
#  order_id   :bigint           not null
#  user_id    :bigint
#
# Indexes
#
#  index_order_events_on_company_id_and_created_at  (company_id,created_at)
#  index_order_events_on_order_id                   (order_id)
#  index_order_events_on_user_id                    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
