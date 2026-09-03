# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    month { "2026-09-03" }
    amount { "9.99" }
    owner { nil }
  end
end

# == Schema Information
#
# Table name: accounts
#
#  id         :bigint           not null, primary key
#  amount     :decimal(10, 2)
#  month      :date
#  owner_type :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  owner_id   :bigint           not null
#
# Indexes
#
#  index_accounts_on_owner  (owner_type,owner_id)
#
