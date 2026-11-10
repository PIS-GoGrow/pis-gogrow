# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderAccount, type: :model do
  fixtures :orders, :accounts, :schedules, :menus, :providers, :consumers, :users, :companies

  let(:order) { orders(:upcoming_pending_today) }
  let(:account) { accounts(:one_tuviandita_current) }

  describe "associations" do
    it "belongs to an order" do
      order_account = described_class.new(order:, account:)
      expect(order_account.order).to eq(order)
    end

    it "belongs to an account" do
      order_account = described_class.new(order:, account:)
      expect(order_account.account).to eq(account)
    end
  end

  describe "validations" do
    it "enforces uniqueness of order scoped to account" do
      described_class.where(order:, account:).delete_all
      described_class.create!(order:, account:)
      duplicate = described_class.new(order:, account:)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:order_id]).to be_present
    end
  end
end

# == Schema Information
#
# Table name: order_accounts
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  order_id   :bigint           not null
#
# Indexes
#
#  index_order_accounts_on_account_id               (account_id)
#  index_order_accounts_on_account_id_and_order_id  (account_id,order_id) UNIQUE
#  index_order_accounts_on_order_id                 (order_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (order_id => orders.id)
#
