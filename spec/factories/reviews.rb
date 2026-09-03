# frozen_string_literal: true

FactoryBot.define do
  factory :review do
    description { "MyString" }
    rating { 1 }
    menu { nil }
  end
end
