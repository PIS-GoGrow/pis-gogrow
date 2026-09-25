# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order, type: :model do
  fixtures :orders, :schedules, :menus, :providers, :consumers, :companies, :users

  it { is_expected.to define_enum_for(:status).with_values(pending: 0, confirmed: 1, cancelled: 2, rejected: 3) }
  it { is_expected.to define_enum_for(:delivery_method).with_values(office: 0, home: 1) }
  it do
    expect(subject).to define_enum_for(:rejection_reason)
      .with_values(out_of_stock: 0, duplicate_order: 1, customer_request: 2, order_error: 3, other: 4)
      .with_prefix(:rejection_reason)
  end

  describe "rejection reason validations" do
    let(:order) { orders(:upcoming_pending_today) }

    it "is valid without rejection reason while pending, confirmed or cancelled" do
      expect(order).to be_valid

      order.status = :confirmed
      expect(order).to be_valid

      order.status = :cancelled
      expect(order).to be_valid
    end

    it "requires a rejection reason when rejected" do
      order.status = :rejected
      order.rejection_reason = nil

      expect(order).not_to be_valid
      expect(order.errors[:rejection_reason]).to include(
        I18n.t("activerecord.errors.models.order.attributes.rejection_reason.blank")
      )
    end

    it "is valid with a standard rejection reason without details" do
      order.status = :rejected
      order.rejection_reason = :out_of_stock
      order.rejection_details = nil

      expect(order).to be_valid
    end

    it "requires rejection_details when reason is other" do
      order.status = :rejected
      order.rejection_reason = :other
      order.rejection_details = nil

      expect(order).not_to be_valid
      expect(order.errors[:rejection_details]).to include(
        I18n.t("activerecord.errors.models.order.attributes.rejection_details.blank")
      )
    end

    it "is valid with other reason and details present" do
      order.status = :rejected
      order.rejection_reason = :other
      order.rejection_details = "Sin insumos"

      expect(order).to be_valid
    end
  end

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

  describe "#decide" do
    it "confirms a pending order and returns true" do
      order = orders(:upcoming_pending_today)

      expect(order.decide(:confirmed)).to be(true)
      expect(order.reload).to be_confirmed
    end

    it "rejects a pending order with a valid reason and returns true" do
      order = orders(:upcoming_pending_today)

      expect(order.decide(:rejected, reason: :out_of_stock)).to be(true)
      expect(order.reload).to be_rejected
      expect(order.rejection_reason).to eq("out_of_stock")
      expect(order.rejection_details).to be_nil
    end

    it "rejects a pending order with 'other' reason and details" do
      order = orders(:upcoming_pending_today)

      expect(order.decide(:rejected, reason: :other, details: "Cocina cerrada")).to be(true)
      expect(order.reload).to be_rejected
      expect(order.rejection_reason).to eq("other")
      expect(order.rejection_details).to eq("Cocina cerrada")
    end

    it "refuses to reject without a reason" do
      order = orders(:upcoming_pending_today)

      expect(order.decide(:rejected)).to be(false)
      expect(order.reload).to be_pending
      expect(order.errors[:rejection_reason]).to be_present
    end

    it "refuses to reject with 'other' reason when details are missing" do
      order = orders(:upcoming_pending_today)

      expect(order.decide(:rejected, reason: :other)).to be(false)
      expect(order.reload).to be_pending
      expect(order.errors[:rejection_details]).to be_present
    end

    it "gives reserved units back to the schedule when rejected" do
      order = orders(:upcoming_pending_today)

      expect { order.decide(:rejected, reason: :out_of_stock) }
        .to change { order.schedule.reload.remaining_amount }.by(order.amount)
    end

    it "refuses to decide an already confirmed order and returns false" do
      order = orders(:upcoming_confirmed_future)

      expect(order.decide(:rejected)).to be(false)
      expect(order.reload).to be_confirmed
    end

    it "refuses to decide an already cancelled order and returns false" do
      order = orders(:history_cancelled_future)

      expect(order.decide(:confirmed)).to be(false)
      expect(order.reload).to be_cancelled
    end

    it "refuses to decide an already rejected order and returns false" do
      order = orders(:history_rejected_future)

      expect(order.decide(:confirmed)).to be(false)
      expect(order.reload).to be_rejected
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
#  delivery_method            :integer          not null
#  discounted_price           :decimal(10, 2)
#  modified_at                :datetime
#  notes                      :string
#  price                      :decimal(10, 2)
#  rejection_details          :string
#  rejection_reason           :integer
#  status                     :integer          default(0), not null
#  status_before_cancellation :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  cancelled_by_id            :bigint
#  consumer_id                :bigint           not null
#  modified_by_id             :bigint
#  schedule_id                :bigint
#
# Indexes
#
#  index_orders_on_cancelled_by_id  (cancelled_by_id)
#  index_orders_on_consumer_id      (consumer_id)
#  index_orders_on_modified_by_id   (modified_by_id)
#  index_orders_on_schedule_id      (schedule_id)
#
# Foreign Keys
#
#  fk_rails_...  (cancelled_by_id => users.id)
#  fk_rails_...  (consumer_id => consumers.id)
#  fk_rails_...  (modified_by_id => users.id)
#  fk_rails_...  (schedule_id => schedules.id)
#
