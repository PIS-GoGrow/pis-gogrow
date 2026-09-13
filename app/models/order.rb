# frozen_string_literal: true

class Order < ApplicationRecord
  enum :status, { pending: 0, confirmed: 1, delivered: 2, cancelled: 3 }

  belongs_to :consumer
  belongs_to :schedule

  has_many :order_accounts, dependent: :destroy
  has_many :accounts, through: :order_accounts
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
