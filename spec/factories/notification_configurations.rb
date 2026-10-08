# frozen_string_literal: true

FactoryBot.define do
  factory :notification_configuration, class: "Notification::Configuration" do
    key { "my_key" }
  end
end

# == Schema Information
#
# Table name: notification_configurations
#
#  id         :bigint           not null, primary key
#  key        :string           not null
#  roles      :string           default([]), is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_notification_configurations_on_key  (key) UNIQUE
#
