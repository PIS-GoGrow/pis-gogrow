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

  describe "#cancellation_block_reason" do
    it "lets a pending order be cancelled even on its delivery day" do
      expect(orders(:upcoming_pending_today)).to be_cancellable
    end

    it "lets a confirmed order be cancelled while its delivery day is still ahead" do
      expect(orders(:upcoming_confirmed_future)).to be_cancellable
    end

    it "blocks a confirmed order once its delivery day arrived" do
      order = orders(:upcoming_pending_today)
      order.update!(status: :confirmed)

      expect(order).not_to be_cancellable
      expect(order.cancellation_block_reason).to eq("confirmed_for_today")
    end

    it "blocks a confirmed order whose delivery day already passed" do
      expect(orders(:history_confirmed_past).cancellation_block_reason).to eq("already_closed")
    end

    it "blocks orders that are already cancelled or rejected" do
      expect(orders(:history_cancelled_future).cancellation_block_reason).to eq("already_closed")
      expect(orders(:history_rejected_future).cancellation_block_reason).to eq("already_closed")
    end

    it "blocks a pending order whose delivery day already passed" do
      expect(orders(:history_pending_past).cancellation_block_reason).to eq("already_closed")
    end

    it "blocks an order left without a delivery date whatever its status" do
      order = orders(:history_without_schedule)

      expect(order.cancellation_block_reason).to eq("unavailable")

      order.status = :confirmed
      expect(order.cancellation_block_reason).to eq("unavailable")
    end
  end

  describe "#cancel" do
    let(:employee) { users(:one) }

    it "records the new state, who cancelled it, when, and the state it came from" do
      order = orders(:upcoming_confirmed_future)

      expect(order.cancel(by: employee)).to be(true)

      order.reload
      expect(order).to be_cancelled
      expect(order.cancelled_by).to eq(employee)
      expect(order.cancelled_at).to be_present
      expect(order.status_before_cancellation).to eq("confirmed")
    end

    it "gives the reserved units back to the schedule" do
      order = orders(:upcoming_confirmed_future)

      expect { order.cancel(by: employee) }
        .to change { order.schedule.reload.remaining_amount }.by(order.amount)
    end

    it "ignores a second cancellation instead of overwriting the first one" do
      order = orders(:upcoming_confirmed_future)
      order.cancel(by: employee)
      cancelled_at = order.reload.cancelled_at

      expect(order.cancel(by: employee)).to be(false)
      expect(order.reload.cancelled_at).to eq(cancelled_at)
    end

    it "refuses to cancel a confirmed order on its delivery day" do
      order = orders(:upcoming_pending_today)
      order.update!(status: :confirmed)

      expect(order.cancel(by: employee)).to be(false)
      expect(order.reload).to be_confirmed
    end

    it "refuses to cancel a pending order whose delivery day already passed" do
      order = orders(:history_pending_past)

      expect(order.cancel(by: employee)).to be(false)
      expect(order.reload).to be_pending
    end

    it "returns false instead of raising when the order no longer passes its validations" do
      order = orders(:upcoming_pending_future)
      order.update_column(:amount, nil)

      expect(order.cancel(by: employee)).to be(false)
      expect(order.reload).to be_pending
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
#  id                         :bigint           not null, primary key
#  address                    :string
#  amount                     :integer
#  cancelled_at               :datetime
#  discounted_price           :decimal(10, 2)
#  notes                      :string
#  price                      :decimal(10, 2)
#  status                     :integer          default(0), not null
#  status_before_cancellation :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  cancelled_by_id            :bigint
#  consumer_id                :bigint           not null
#  schedule_id                :bigint
#
# Indexes
#
#  index_orders_on_cancelled_by_id  (cancelled_by_id)
#  index_orders_on_consumer_id      (consumer_id)
#  index_orders_on_schedule_id      (schedule_id)
#
# Foreign Keys
#
#  fk_rails_...  (cancelled_by_id => users.id)
#  fk_rails_...  (consumer_id => consumers.id)
#  fk_rails_...  (schedule_id => schedules.id)
#
