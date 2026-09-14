# frozen_string_literal: true

class Order < ApplicationRecord
  enum :status, { pending: 0, completed: 1, canceled: 2 }, default: :pending

  belongs_to :consumer
  belongs_to :schedule

  has_many :order_accounts, dependent: :destroy
  has_many :accounts, through: :order_accounts

  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :discounted_price, comparison: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price, comparison: { greater_than_or_equal_to: 0 }, presence: true

  def self.reserve(consumer:, schedule:, quantity: 1, notes: nil, address: consumer.address, discount_percentage: 0)
    gross_price = schedule.menu.price * quantity
    discounted_price = gross_price * (100 - discount_percentage.clamp(0, 100)) / 100
    order = new(consumer:, schedule:, amount: quantity, notes:, address:, price: gross_price, discounted_price:)

    schedule.with_lock do
      if schedule.available?(quantity:)
        order.save
      else
        order.errors.add(:schedule_id, I18n.t("validations.schedule_unavailable"))
      end
    end

    order
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
#  status           :integer
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
