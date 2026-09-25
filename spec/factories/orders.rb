# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    price { "9.99" }
    discounted_price { "9.99" }
    address { "MyString" }
    amount { 1 }
    notes { "MyString" }
    status { 1 }
    delivery_method { :office }
    consumer { nil }
    schedule { nil }
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
