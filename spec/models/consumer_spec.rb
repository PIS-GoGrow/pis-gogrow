# frozen_string_literal: true

require "rails_helper"

RSpec.describe Consumer, type: :model do
  fixtures :consumers, :companies, :providers

  let(:consumer) { consumers(:one) }
  let(:company_address) { companies(:gogrow).address }

  describe "#delivery_for" do
    it "derives office when the company address is chosen" do
      expect(consumer.delivery_for(providers(:tuviandita), company_address))
        .to eq({ delivery_method: "office", address: company_address })
    end

    it "derives home when another address is chosen and the provider delivers home" do
      expect(consumer.delivery_for(providers(:tuviandita), consumer.address))
        .to eq({ delivery_method: "home", address: consumer.address })
    end

    it "forces office with the company address for an office-only provider" do
      expect(consumer.delivery_for(providers(:office_provider), consumer.address))
        .to eq({ delivery_method: "office", address: company_address })
    end
  end

  describe "subsidized meals calculations" do
    before do
      Order.delete_all
      Schedule.delete_all
    end

    let(:menu) { menus(:milanesa) }
    let(:today_schedule) { Schedule.create!(menu:, date: Date.current, amount: 30) }

    it "counts orders delivered within the current month" do
      Order.create!(
        consumer:, schedule: today_schedule, amount: 3,
        price: 900, address: consumer.company.address, delivery_method: :office, status: :confirmed
      )

      expect(consumer.subsidized_meals_used_this_month).to eq(3)
      expect(consumer.remaining_subsidized_meals).to eq(17)
    end

    it "does not count cancelled or rejected orders" do
      Order.create!(
        consumer:, schedule: today_schedule, amount: 2,
        price: 600, address: consumer.company.address, delivery_method: :office, status: :cancelled
      )
      Order.create!(
        consumer:, schedule: today_schedule, amount: 1,
        price: 300, address: consumer.company.address, delivery_method: :office, status: :rejected
      )

      expect(consumer.subsidized_meals_used_this_month).to eq(0)
      expect(consumer.remaining_subsidized_meals).to eq(20)
    end

    it "does not count orders delivered in previous or future months" do
      past_schedule = Schedule.create!(menu:, date: 1.month.ago.beginning_of_month, amount: 30)
      future_schedule = Schedule.create!(menu:, date: 1.month.from_now.beginning_of_month, amount: 30)

      Order.create!(
        consumer:, schedule: past_schedule, amount: 5,
        price: 1500, address: consumer.company.address, delivery_method: :office, status: :confirmed
      )
      Order.create!(
        consumer:, schedule: future_schedule, amount: 4,
        price: 1200, address: consumer.company.address, delivery_method: :office, status: :confirmed
      )

      expect(consumer.subsidized_meals_used_this_month).to eq(0)
      expect(consumer.remaining_subsidized_meals).to eq(20)
    end

    it "clamps remaining subsidized meals to zero when limit is exceeded" do
      Order.create!(
        consumer:, schedule: today_schedule, amount: 25,
        price: 7500, address: consumer.company.address, delivery_method: :office, status: :confirmed
      )

      expect(consumer.subsidized_meals_used_this_month).to eq(25)
      expect(consumer.remaining_subsidized_meals).to eq(0)
    end
  end

  describe "#benefit_available" do
    it "returns the amount of the active monthly benefit" do
      Benefit.create!(
        consumer:, amount: 15, percentage: 50,
        due_date: 1.month.from_now, description: "Viandas mensuales"
      )

      expect(consumer.benefit_available).to eq(15)
    end

    it "returns 0 when there is no active monthly benefit" do
      expect(consumer.benefit_available).to eq(0)
    end
  end

  describe "debt and spending" do
    let(:provider) { providers(:tuviandita) }

    it "sums pending accounts for total debt" do
      Account.create!(owner: consumer, provider:, month: 1.month.ago.beginning_of_month, amount: 300)
      Account.create!(owner: consumer, provider:, month: Date.current.beginning_of_month, amount: 450)
      paid_account = Account.create!(owner: consumer, provider:, month: 2.months.ago.beginning_of_month, amount: 200)
      Payment.create!(account: paid_account, status: 0)

      expect(consumer.total_debt).to eq(750)
    end

    it "sums current month accounts for current_month_spending" do
      Account.create!(owner: consumer, provider:, month: Date.current.beginning_of_month, amount: 450)
      Account.create!(owner: consumer, provider:, month: 1.month.ago.beginning_of_month, amount: 300)

      expect(consumer.current_month_spending).to eq(450)
    end
  end
end

# == Schema Information
#
# Table name: consumers
#
#  id         :bigint           not null, primary key
#  address    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_consumers_on_company_id  (company_id)
#  index_consumers_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (user_id => users.id)
#
