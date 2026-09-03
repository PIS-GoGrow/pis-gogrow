# frozen_string_literal: true

FactoryBot.define do
  factory :schedule do
    date { "2026-09-03" }
    amount { 1 }
    menu { nil }
  end
end
