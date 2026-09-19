# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order, type: :model do
  fixtures :orders, :schedules, :menus, :providers, :consumers, :companies, :users

  it { is_expected.to define_enum_for(:status).with_values(pending: 0, confirmed: 1, cancelled: 2, rejected: 3) }
  it { is_expected.to define_enum_for(:delivery_method).with_values(office: 0, home: 1) }

  describe "delivery method by provider" do
    it "rejects home for an office-only provider" do
      order = Order.new(consumer: consumers(:one), schedule: schedules(:office), amount: 1, price: 100, discounted_price: 100, address: "Dirección", delivery_method: :home)

      expect(order).not_to be_valid
      expect(order.errors[:delivery_method]).to include(I18n.t("validations.delivery_method_not_allowed"))
    end

    it "accepts office for an office-only provider" do
      order = Order.new(consumer: consumers(:one), schedule: schedules(:office), amount: 1, price: 100, discounted_price: 100, address: "Dirección", delivery_method: :office)

      expect(order).to be_valid
    end
  end

  describe "delivery method snapshot" do
    it "stays updatable when the provider turns home delivery off" do
      order = Order.create!(consumer: consumers(:one), schedule: schedules(:future), amount: 1, price: 100, discounted_price: 100, address: consumers(:one).address, delivery_method: :home)
      order.schedule.menu.provider.update!(home_delivery: false)

      order.update!(status: :confirmed)

      expect(order.reload).to have_attributes(status: "confirmed", delivery_method: "home")
    end

    it "does not flag the delivery method of an order left without a schedule" do
      order = orders(:history_without_schedule)

      order.valid?

      expect(order.errors[:delivery_method]).to be_empty
    end
  end

  describe "database guarantees" do
    it "rejects an order without a delivery method" do
      expect do
        Order.new(consumer: consumers(:one), schedule: schedules(:future), amount: 1, price: 100, discounted_price: 100, address: "Dirección").save(validate: false)
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects home without an address" do
      order = orders(:upcoming_confirmed_future)
      order.update_column(:address, nil)

      expect { order.update_column(:delivery_method, 1) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe ".upcoming" do
    it "includes orders whose delivery date has not passed yet" do
      expect(described_class.upcoming).to include(
        orders(:upcoming_pending_future),
        orders(:upcoming_confirmed_future),
        orders(:upcoming_pending_today)
      )
    end

    it "excludes cancelled, rejected, past and scheduleless orders" do
      expect(described_class.upcoming).not_to include(
        orders(:history_cancelled_future),
        orders(:history_rejected_future),
        orders(:history_confirmed_past),
        orders(:history_pending_past),
        orders(:history_without_schedule)
      )
    end

    it "sorts by delivery date, closest first" do
      expect(described_class.upcoming.first).to eq(orders(:upcoming_pending_today))
    end
  end

  describe ".history" do
    it "includes cancelled and rejected orders even when their delivery date is still ahead" do
      expect(described_class.history).to include(
        orders(:history_cancelled_future),
        orders(:history_rejected_future)
      )
    end

    it "includes orders left without a schedule" do
      expect(described_class.history).to include(orders(:history_without_schedule))
    end

    it "excludes upcoming orders" do
      expect(described_class.history).not_to include(orders(:upcoming_confirmed_future))
    end
  end

  describe "#subsidy" do
    it "is what the company covers: the gap between the full price and what the employee pays" do
      expect(orders(:upcoming_confirmed_future).subsidy).to eq(300.50)
    end

    it "is nil when either amount is missing" do
      order = orders(:upcoming_confirmed_future)
      order.discounted_price = nil

      expect(order.subsidy).to be_nil
    end
  end

  it "splits every order between the two sections" do
    expect(described_class.upcoming.ids & described_class.history.ids).to be_empty
    expect(described_class.upcoming.count + described_class.history.count).to eq(described_class.count)
  end
end

# == Schema Information
#
# Table name: orders
#
#  id               :bigint           not null, primary key
#  address          :string
#  amount           :integer
#  delivery_method  :integer          not null
#  discounted_price :decimal(10, 2)
#  notes            :string
#  price            :decimal(10, 2)
#  status           :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  consumer_id      :bigint           not null
#  schedule_id      :bigint
#
# Indexes
#
#  index_orders_on_consumer_id  (consumer_id)
#  index_orders_on_schedule_id  (schedule_id)
#
# Foreign Keys
#
#  fk_rails_...  (consumer_id => consumers.id)
#  fk_rails_...  (schedule_id => schedules.id)
#
