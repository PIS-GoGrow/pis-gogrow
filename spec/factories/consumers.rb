# frozen_string_literal: true

FactoryBot.define do
  factory :consumer do
    email { "MyString" }
    username { "MyString" }
    address { "MyString" }
    company { nil }
  end
end

# == Schema Information
#
# Table name: consumers
#
#  id         :bigint           not null, primary key
#  address    :string
#  email      :string
#  username   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_consumers_on_company_id  (company_id)
#  index_consumers_on_email       (email) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
