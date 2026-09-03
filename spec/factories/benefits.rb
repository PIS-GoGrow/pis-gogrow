# frozen_string_literal: true

FactoryBot.define do
  factory :benefit do
    amount { 1 }
    description { "MyString" }
    percentage { 1 }
    due_date { "2026-09-03" }
    consumer { nil }
  end
end
