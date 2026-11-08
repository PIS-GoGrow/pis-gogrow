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
