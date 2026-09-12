# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order, type: :model do
  fixtures :orders, :schedules, :menus, :providers, :consumers, :companies, :users

  it { is_expected.to define_enum_for(:status).with_values(pending: 0, confirmed: 1, cancelled: 2, rejected: 3) }

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
