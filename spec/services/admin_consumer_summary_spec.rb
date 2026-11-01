# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminConsumerSummary do
  fixtures :users, :companies, :consumers, :providers, :benefit_configurations,
           :benefit_rules, :benefits, :menus, :schedules, :accounts, :payments, :orders

  let(:consumer) { consumers(:one) }
  let(:provider1) { providers(:tuviandita) }
  let(:provider2) { providers(:endulzate) }
  let(:summary) { described_class.new(consumer) }

  describe "#current_month" do
    before do
      Order.destroy_all
      Schedule.delete_all
    end

    let(:menu1) { menus(:milanesa) }
    let(:menu2) do
      Menu.create!(provider: provider2, name: "Tarta casera", description: "Con masa casera", price: 300)
    end
    let(:schedule_today1) { Schedule.create!(menu: menu1, date: Date.current, amount: 20) }
    let(:schedule_today2) { Schedule.create!(menu: menu2, date: Date.current, amount: 20) }

    it "reports meals_used and meals_limit matching the consumer unified calculations" do
      order1 = Order.create!(
        consumer:, schedule: schedule_today1, amount: 2,
        price: 600, address: consumer.company.address, delivery_method: :office, status: :confirmed
      )
      order1.apply_benefit! benefits(:monthly), 2

      order2 = Order.create!(
        consumer:, schedule: schedule_today2, amount: 3,
        price: 900, address: consumer.company.address, delivery_method: :office, status: :pending
      )
      order2.apply_benefit! benefits(:monthly), 1

      current_month_data = summary.current_month

      expect(current_month_data[:meals_used]).to eq(3)
      expect(current_month_data[:meals_limit]).to eq(20)
      expect(current_month_data[:meals_used]).to eq(consumer.monthly_benefit_used_this_month)
    end

    it "breaks down meals by provider based on monthly_benefit_usages" do
      # Provider 1 has 2 confirmed subsidized meals
      order1 = Order.create!(
        consumer:, schedule: schedule_today1, amount: 2,
        price: 600, address: consumer.company.address, delivery_method: :office, status: :confirmed
      )
      order1.apply_benefit! benefits(:monthly), 2

      # Provider 2 has 1 pending subsidized meal and 2 unsubsidized meals in the same order
      order2 = Order.create!(
        consumer:, schedule: schedule_today2, amount: 3,
        price: 900, address: consumer.company.address, delivery_method: :office, status: :pending
      )
      order2.apply_benefit! benefits(:monthly), 1

      # Cancelled order with Provider 1 should be excluded
      order3 = Order.create!(
        consumer:, schedule: schedule_today1, amount: 4,
        price: 1200, address: consumer.company.address, delivery_method: :office, status: :cancelled
      )
      order3.apply_benefit! benefits(:monthly), 4

      providers_summary = summary.current_month[:providers]

      expect(providers_summary).to contain_exactly(
        { name: provider1.user.name, meals: 2 },
        { name: provider2.user.name, meals: 1 }
      )
      expect(providers_summary.sum { |p| p[:meals] }).to eq(summary.current_month[:meals_used])
    end

    it "does not include providers from other consumers or out-of-month orders" do
      past_schedule = Schedule.create!(menu: menu1, date: 1.month.ago.beginning_of_month, amount: 10)
      Order.create!(
        consumer:, schedule: past_schedule, amount: 5,
        price: 1500, address: consumer.company.address, delivery_method: :office, status: :confirmed
      ).apply_benefit! benefits(:monthly), 5

      other_consumer = consumers(:other)
      other_benefit = Benefit.create!(
        consumer: other_consumer,
        benefit_configuration: benefit_configurations(:monthly),
        status: :current,
        percentage: 50,
        amount: 20,
        due_date: Date.current.end_of_month
      )
      other_order = Order.create!(
        consumer: other_consumer, schedule: schedule_today1, amount: 2,
        price: 600, address: other_consumer.company.address, delivery_method: :office, status: :confirmed
      )
      other_order.apply_benefit! other_benefit, 2

      expect(summary.current_month[:providers]).to be_empty
      expect(summary.current_month[:meals_used]).to eq(0)
    end
  end
end
