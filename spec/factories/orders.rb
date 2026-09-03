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
