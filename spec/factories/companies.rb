# frozen_string_literal: true

FactoryBot.define do
  factory :company do
    name { "MyString" }
    address { "MyString" }
  end
end

# == Schema Information
#
# Table name: companies
#
#  id                   :bigint           not null, primary key
#  address              :string
#  debt_alert_threshold :integer          default(2000), not null
#  name                 :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
