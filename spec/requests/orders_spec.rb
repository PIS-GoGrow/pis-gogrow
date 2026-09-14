# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Orders", type: :request do
  around do |example|
    travel_to(Time.zone.local(2026, 9, 14, 10)) { example.run }
  end

  def setup_consumer
    company = Company.create!(name: "GoGrow", address: "18 de Julio 1006")
    user = User.create!(email: "consumer-orders@gmail.com", name: "Sofía", password: "password123456")
    consumer = Consumer.create!(user:, company:, address: "Ellauri 1234")
    session = user.sessions.create!(role: :consumer)
    cookies[:session_token] = AuthenticationHelpers.signed_cookie(:session_token, session.id)
    [ consumer, company ]
  end

  def create_schedule(price: 300, amount: 5)
    provider_user = User.create!(email: "provider-#{SecureRandom.hex(4)}@gmail.com", name: "Tu Viandita", password: "password123456")
    provider = Provider.create!(user: provider_user)
    menu = Menu.create!(provider:, name: "Milanesa", description: "Con puré", price:)
    Schedule.create!(menu:, date: Date.current.beginning_of_week(:monday), amount:)
  end

  it "creates the cart atomically with server prices, benefit and delivery address" do
    consumer, company = setup_consumer
    schedule = create_schedule
    Benefit.create!(consumer:, amount: 5, percentage: 50, due_date: 1.month.from_now)

    expect do
      post orders_path, params: {
        order: {
          address: company.address,
          items: [ { schedule_id: schedule.id, quantity: 2, notes: "Sin salsa" } ]
        }
      }
    end.to change(Order, :count).by(1)

    expect(response).to redirect_to(dashboard_path)
    order = Order.last
    expect(order).to have_attributes(
      consumer:,
      schedule:,
      amount: 2,
      address: company.address,
      price: 600.to_d,
      discounted_price: 300.to_d,
      notes: "Sin salsa"
    )
  end

  it "does not create a partial cart when one item is unavailable" do
    consumer, = setup_consumer
    available = create_schedule
    unavailable = create_schedule(amount: 1)
    Order.create!(consumer:, schedule: unavailable, amount: 1, price: unavailable.menu.price)

    expect do
      post orders_path, params: {
        order: {
          address: consumer.address,
          items: [
            { schedule_id: available.id, quantity: 1 },
            { schedule_id: unavailable.id, quantity: 1 }
          ]
        }
      }
    end.not_to change(Order, :count)

    expect(response).to redirect_to(dashboard_path)
  end

  it "rejects an empty cart" do
    consumer, = setup_consumer

    expect do
      post orders_path, params: { order: { address: consumer.address, items: [] } }
    end.not_to change(Order, :count)

    expect(response).to redirect_to(dashboard_path)
  end
end
