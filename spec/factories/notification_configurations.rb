# frozen_string_literal: true

FactoryBot.define do
  factory :notification_configuration do
    description { "MyString" }
  end
end

# == Schema Information
#
# Table name: notification_configurations
#
#  id          :bigint           not null, primary key
#  description :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
