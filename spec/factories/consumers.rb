# frozen_string_literal: true

FactoryBot.define do
  factory :consumer do
    email { "MyString" }
    username { "MyString" }
    address { "MyString" }
    company { nil }
  end
end
