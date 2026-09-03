# frozen_string_literal: true

FactoryBot.define do
  factory :user_notification do
    notification_configuration { nil }
    user { nil }
  end
end
