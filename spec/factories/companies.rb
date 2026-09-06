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
#  id         :bigint           not null, primary key
#  address    :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
