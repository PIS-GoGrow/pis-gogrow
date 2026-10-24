# frozen_string_literal: true

FactoryBot.define do
  factory :review do
    description { "MyString" }
    rating { 1 }
    menu { nil }
  end
end

# == Schema Information
#
# Table name: reviews
#
#  id          :bigint           not null, primary key
#  description :string
#  rating      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  consumer_id :bigint
#  menu_id     :bigint           not null
#  order_id    :bigint
#
# Indexes
#
#  index_reviews_on_consumer_id  (consumer_id)
#  index_reviews_on_menu_id      (menu_id)
#  index_reviews_on_order_id     (order_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (consumer_id => consumers.id)
#  fk_rails_...  (menu_id => menus.id)
#  fk_rails_...  (order_id => orders.id)
#
