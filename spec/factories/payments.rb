# frozen_string_literal: true

FactoryBot.define do
  factory :payment do
    status { 1 }
    account { nil }
  end
end
