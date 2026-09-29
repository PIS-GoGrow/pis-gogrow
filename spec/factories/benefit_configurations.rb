# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_configuration do
    name { "MyString" }
    subsidy_percentage { 50 }
    created_by { nil }
    company { nil }
  end
end
