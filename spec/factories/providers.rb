# frozen_string_literal: true

FactoryBot.define do
  factory :provider do
    email { "MyString" }
    username { "MyString" }
    order_deadline { "2026-09-03 20:54:50" }
  end
end

# == Schema Information
#
# Table name: providers
#
#  id             :bigint           not null, primary key
#  email          :string
#  order_deadline :time
#  username       :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_providers_on_email  (email) UNIQUE
#
