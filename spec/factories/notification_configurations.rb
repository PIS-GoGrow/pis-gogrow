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
#  key         :string           not null
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_notification_configurations_on_key  (key) UNIQUE
#
