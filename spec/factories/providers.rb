# frozen_string_literal: true

FactoryBot.define do
  factory :provider do
    email { "MyString" }
    username { "MyString" }
    order_deadline { "2026-09-03 20:54:50" }
  end
end
