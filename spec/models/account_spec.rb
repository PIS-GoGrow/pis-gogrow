# frozen_string_literal: true

require "rails_helper"

RSpec.describe Account, type: :model do
  fixtures :accounts, :payments, :consumers, :companies, :users

  describe ".pending" do
    it "includes accounts with no payment, or none accredited, and excludes settled ones" do
      expect(Account.pending).to contain_exactly(accounts(:unpaid), accounts(:failed_payment))
    end
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
