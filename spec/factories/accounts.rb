# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    month { "2026-09-03" }
    amount { "9.99" }
    owner { nil }
  end
end
