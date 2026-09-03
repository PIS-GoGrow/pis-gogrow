# frozen_string_literal: true

FactoryBot.define do
  factory :menu do
    name { "MyString" }
    description { "MyString" }
    price { "9.99" }
    provider { nil }
  end
end
