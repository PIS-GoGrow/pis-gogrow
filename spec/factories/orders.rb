# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    price { "9.99" }
    discounted_price { "9.99" }
    address { "MyString" }
    amount { 1 }
    notes { "MyString" }
    status { 1 }
    consumer { nil }
    schedule { nil }
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
