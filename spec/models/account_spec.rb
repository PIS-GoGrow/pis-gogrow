# frozen_string_literal: true

require "rails_helper"

RSpec.describe Account, type: :model do
  fixtures :users

  let(:company) { Company.create!(name: "GoGrow", address: "18 de Julio 1006") }
  let(:consumer_user) { User.create!(email: "consumer-account-test@gmail.com", name: "Lucía", password: "password123456") }
  let(:consumer) { Consumer.create!(user: consumer_user, company:, address: "Ellauri 1234") }

  let(:provider_user) { User.create!(email: "provider-account-test@gmail.com", name: "Rotisería Central", password: "password123456") }
  let(:provider) { Provider.create!(user: provider_user) }

  describe "callbacks and helpers" do
    it "normalizes month to the beginning of the month" do
      account = Account.create!(
        owner: consumer,
        provider: provider,
        month: Date.new(2026, 9, 15),
        amount: 500
      )

      expect(account.month).to eq(Date.new(2026, 9, 1))
    end

    it "identifies if it corresponds to the current month" do
      current_account = Account.create!(
        owner: consumer,
        provider: provider,
        month: Date.current,
        amount: 300
      )

      past_account = Account.create!(
        owner: consumer,
        provider: provider,
        month: 2.months.ago,
        amount: 300
      )

      expect(current_account.current?).to be(true)
      expect(past_account.current?).to be(false)
    end

    it "calculates the due date as the 5th day after the following month" do
      account = Account.create!(
        owner: consumer,
        provider: provider,
        month: Date.new(2026, 9, 1),
        amount: 400
      )

      expect(account.due_date).to eq(Date.new(2026, 10, 5))
    end
  end

  describe "#sync_amount!" do
    it "updates the account amount with the sum of final discounted prices of confirmed orders" do
      menu = Menu.create!(provider:, name: "Tarta", description: "Pascualina", price: 300)
      schedule = Schedule.create!(menu:, date: Date.current.beginning_of_week(:monday), amount: 10)

      account = consumer.accounts.create!(provider:, month: Date.current, amount: 0)

      order1 = Order.create!(
        consumer:,
        schedule:,
        amount: 1,
        price: 300,
        discounted_price: 150,
        address: consumer.company.address,
        delivery_method: :office,
        status: :confirmed
      )
      order2 = Order.create!(
        consumer:,
        schedule:,
        amount: 2,
        price: 600,
        discounted_price: 300,
        address: consumer.company.address,
        delivery_method: :office,
        status: :confirmed
      )
      Order.create!(
        consumer:,
        schedule:,
        amount: 1,
        price: 300,
        discounted_price: 150,
        address: consumer.company.address,
        delivery_method: :office,
        status: :cancelled
      )

      # Ensure orders are linked to this account
      account.orders = [ order1, order2 ]
      account.sync_amount!

      expect(account.reload.amount).to eq(450.to_d)
    end
  end

  describe ".amount_and_price_sum" do
    it "aggregates total amounts and final discounted prices for confirmed orders of the given accounts" do
      menu = Menu.create!(provider:, name: "Milanesa", description: "Con puré", price: 350)
      schedule = Schedule.create!(menu:, date: Date.current.beginning_of_week(:monday), amount: 15)

      account = consumer.accounts.create!(provider:, month: Date.current, amount: 0)

      order1 = Order.create!(
        consumer:,
        schedule:,
        amount: 2,
        price: 700,
        discounted_price: 350,
        address: consumer.company.address,
        delivery_method: :office,
        status: :confirmed
      )
      order2 = Order.create!(
        consumer:,
        schedule:,
        amount: 1,
        price: 350,
        discounted_price: 175,
        address: consumer.company.address,
        delivery_method: :office,
        status: :confirmed
      )
      OrderAccount.find_or_create_by!(order: order1, account: account)
      OrderAccount.find_or_create_by!(order: order2, account: account)

      sums = Account.amount_and_price_sum([ account.id ])

      expect(sums[account.id]).to eq({
        amount: 3,
        price: 525.to_d
      })
    end
  end

  describe "scopes: pending and history" do
    it "filters pending accounts with positive amount and without approved payments" do
      pending_account = Account.create!(
        owner: consumer,
        provider: provider,
        month: Date.current,
        amount: 450
      )
      paid_account = Account.create!(
        owner: consumer,
        provider: provider,
        month: 1.month.ago,
        amount: 300
      )
      Payment.create!(account: paid_account, status: 0)

      zero_account = Account.create!(
        owner: consumer,
        provider: provider,
        month: 2.months.ago,
        amount: 0
      )

      expect(Account.pending).to include(pending_account)
      expect(Account.pending).not_to include(paid_account)
      expect(Account.pending).not_to include(zero_account)
      expect(Account.history).to include(paid_account)
    end
  end

  describe "Consumer debt methods" do
    it "calculates current_month_spending and total_debt correctly" do
      Account.create!(
        owner: consumer,
        provider: provider,
        month: Date.current,
        amount: 350
      )
      Account.create!(
        owner: consumer,
        provider: provider,
        month: 1.month.ago,
        amount: 400
      )

      expect(consumer.current_month_spending).to eq(350.to_d)
      expect(consumer.total_debt).to eq(750.to_d)
    end
  end
end

# == Schema Information
#
# Table name: accounts
#
#  id          :bigint           not null, primary key
#  amount      :decimal(10, 2)
#  month       :date
#  owner_type  :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  owner_id    :bigint           not null
#  provider_id :bigint           not null
#
# Indexes
#
#  idx_on_owner_type_owner_id_provider_id_month_49d9020441  (owner_type,owner_id,provider_id,month) UNIQUE
#  index_accounts_on_owner                                  (owner_type,owner_id)
#  index_accounts_on_provider_id                            (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => providers.id)
#
