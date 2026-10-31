# frozen_string_literal: true

require "rails_helper"

# En los fixtures, el mes en curso tiene la cuenta de GoGrow con Tu Viandita
# (601 de subsidio, sin comprobante) y cuatro viandas confirmadas de los dos
# empleados; el mes anterior, una cuenta de 900 ya aprobada y sin pedidos.
RSpec.describe AdminMonthlySummary do
  fixtures :users, :companies, :admins, :providers, :consumers, :menus, :schedules,
           :orders, :accounts, :order_accounts, :payments, :benefit_configurations, :benefit_rules

  let(:company) { companies(:gogrow) }
  let(:current) { described_class.new(company) }
  let(:previous) { described_class.new(company, 1.month.ago) }

  def create_consumer(name)
    user = User.create!(name:, email: "#{name.parameterize}@example.com", password: "secret-password-123")
    Consumer.create!(user:, company:)
  end

  describe "IVA de las cuentas de empresa (IBP-059)" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("COMPANY_ACCOUNT_VAT_ENABLED").and_return("true")
    end

    let!(:taxed) do
      Account.create!(owner: company, provider: providers(:endulzate), month: Date.current, amount: "800")
    end

    it "adds up the totals with VAT, like Pagos" do
      expect(current.to_h).to include(spending: 1577.0, pending: 1577.0)
    end

    it "shows the total with VAT in the payments of the month" do
      next_month = described_class.new(company, 1.month.from_now)

      expect(next_month.payments.find { it.name == "Other Provider User" }.amount).to eq(976.0)
    end

    it "projects the pending orders with the VAT of their account" do
      OrderAccount.create!(order: orders(:upcoming_pending_today), account: taxed)

      expect(current.projected).to eq(183.31)
    end
  end

  describe "#meals" do
    it "counts the confirmed meals of the month" do
      expect(current.meals).to eq(4)
    end

    it "is zero for a month without orders" do
      expect(previous.meals).to eq(0)
    end
  end

  describe "#meals_limit" do
    it "multiplies the monthly limit by the employees of the company" do
      expect(current.meals_limit).to eq(40)
    end

    it "is nil when the month had no benefit configured" do
      expect(previous.meals_limit).to be_nil
    end
  end

  describe "#participation" do
    it "is the share of employees with a confirmed order in the month" do
      expect(current.participation).to eq(100)

      create_consumer("Sin Pedidos")

      expect(described_class.new(company).participation).to eq(67)
    end

    it "is zero for a month without orders" do
      expect(previous.participation).to eq(0)
    end
  end

  describe "#spending, #paid and #pending" do
    it "split the subsidy of the month by whether it was paid" do
      expect(current.to_h).to include(spending: 601.0, paid: 0.0, pending: 601.0)
      expect(previous.to_h).to include(spending: 900.0, paid: 900.0, pending: 0.0)
    end

    it "ignores the accounts of other companies" do
      other = Company.create!(name: "Otra empresa", address: "Rincón 500")
      Account.create!(owner: other, provider: providers(:tuviandita), month: Date.current, amount: 100.00)

      expect(current.spending).to eq(601.0)
    end
  end

  describe "#projected" do
    it "adds up the subsidy of the orders the provider has not confirmed yet" do
      OrderAccount.create!(order: orders(:upcoming_pending_today), account: accounts(:gogrow_tuviandita_current))

      expect(current.projected).to eq(150.25)
    end

    it "is zero when every order is resolved" do
      expect(current.projected).to eq(0.0)
    end
  end

  describe "#payments" do
    it "lists the accounts of the month before, which is the one paid to providers" do
      expect(current.payments_month).to eq(1.month.ago.to_date.beginning_of_month)
      expect(current.payments.map(&:to_h))
        .to eq([ { name: "Provider User", amount: 900.0, status: "approved" } ])
    end

    it "is empty when that month had nothing to pay" do
      expect(previous.payments).to be_empty
    end
  end

  describe "#debtors" do
    it "ranks the employees that did not settle the month by amount" do
      expect(current.debtors.map { [ it.name, it.amount, it.status ] }).to eq([
        [ "Test User", 950.75, "pending" ],
        [ "Other Consumer User", 150.25, "submitted" ]
      ])
    end

    it "keeps the top three and breaks ties by name" do
      [ "Zoe", "Ana" ].each do |name|
        Account.create!(owner: create_consumer(name), provider: providers(:tuviandita), month: Date.current, amount: 950.75)
      end

      expect(current.debtors.map(&:name)).to eq([ "Ana", "Test User", "Zoe" ])
    end

    it "leaves out who already paid" do
      Payment.new(account: accounts(:one_endulzate_current), status: :approved).save!(validate: false)
      payments(:one_rejected).update_column(:status, Payment.statuses[:approved])

      expect(current.debtors.map(&:name)).to eq([ "Other Consumer User" ])
    end

    it "keeps consumers with a partial payment among the debtors" do
      payments(:one_rejected).update!(status: :partial, rejection_reason: nil)

      debtor = current.debtors.find { it.consumer == consumers(:one) }

      expect(debtor).to be_present
      expect(debtor.status).to eq("partial")
    end

    it "is empty for a month without debts" do
      expect(previous.debtors).to be_empty
    end
  end

  describe "#months" do
    it "goes from the first month with accounts to the current one" do
      expect(current.months).to eq([ Date.current.beginning_of_month, 1.month.ago.to_date.beginning_of_month ])
    end

    it "includes an older month that was asked for without filling the gap" do
      old = Date.new(2020, 1, 1)

      expect(described_class.new(company, old).months.last).to eq(old)
      expect(described_class.new(company, old).months.size).to eq(3)
    end
  end
end
