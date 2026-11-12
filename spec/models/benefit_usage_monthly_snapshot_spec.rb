# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitUsageMonthlySnapshot do
  let(:company) { companies(:gogrow) }
  let(:month) { Date.current.beginning_of_month.prev_month }

  it "stores one aggregate per company and month without employee identifiers" do
    snapshot = historical_snapshot(company:, month:)

    expect(snapshot).to be_fictional
    expect(snapshot.monthly_utilization_percent).to eq(25)
    expect(snapshot.participation_percent).to eq(50)
    expect(snapshot.average_confirmed_meals_per_employee).to eq(4)
    expect(described_class.column_names).not_to include("consumer_id", "user_id", "email", "name")
    expect { historical_snapshot(company:, month:) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "permits fictional snapshots only in test or development" do
    %w[production staging].each do |environment|
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(environment))
      snapshot = described_class.new(company:, month:, captured_at: Time.current, fictional: true)
      expect(snapshot).not_to be_valid
      expect(snapshot.errors[:fictional]).to be_present
    end
  end

  it "rejects a fictional snapshot on an unauthorized database even if Rails says development" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
    snapshot = described_class.new(company:, month:, captured_at: Time.current, fictional: true)

    expect(snapshot).not_to be_valid
    expect(snapshot.errors[:fictional]).to be_present
  end

  it "allows validation of a fictional snapshot only when the development database guard approves" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
    allow(Ibp041::LocalDatabaseGuard).to receive(:allowed?).and_return(true)
    snapshot = described_class.new(company:, month:, captured_at: Time.current, fictional: true)

    expect(snapshot).to be_valid
  end

  it "isolates companies at the same period" do
    another = Company.create!(name: "Empresa ficticia")
    historical_snapshot(company:, month:, monthly_quota_meals: 160)
    historical_snapshot(company: another, month:, monthly_quota_meals: 60)

    expect(described_class.find_by!(company:, month:).monthly_quota_meals).to eq(160)
    expect(described_class.find_by!(company: another, month:).monthly_quota_meals).to eq(60)
  end

  it "enforces the company-month uniqueness in the database" do
    snapshot = historical_snapshot(company:, month:)

    expect do
      described_class.transaction(requires_new: true) do
        described_class.insert_all!([ snapshot.attributes.except("id", "created_at", "updated_at") ])
      end
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "supports distinct fictional months without creating operational records" do
    before = [ Order.count, Benefit.count, Consumer.count ]
    high = historical_snapshot(company:, month: month.prev_month, employees: 12, eligible_employees: 10,
                               employees_with_confirmed_orders: 9, eligible_with_confirmed_orders: 9,
                               eligible_without_orders: 1, monthly_quota_meals: 200, monthly_subsidized_meals: 180,
                               monthly_available_meals: 20, monthly_unused_closed_meals: 20,
                               confirmed_meals: 180, company_subsidy_amount: 9000)
    low = historical_snapshot(company:, month:, employees: 8, eligible_employees: 6,
                              employees_with_confirmed_orders: 1, eligible_with_confirmed_orders: 1,
                              eligible_without_orders: 5, monthly_quota_meals: 120, monthly_subsidized_meals: 10,
                              monthly_available_meals: 110, monthly_unused_closed_meals: 110,
                              confirmed_meals: 10, company_subsidy_amount: 500)

    expect(high.participation_percent).to eq(90)
    expect(low.participation_percent).to eq(BigDecimal("16.67"))
    expect([ Order.count, Benefit.count, Consumer.count ]).to eq(before)
  end

  it "rejects invalid denominators and keeps percentages undefined for zero or missing denominators" do
    snapshot = historical_snapshot(company:, month:, eligible_employees: 0, eligible_with_confirmed_orders: 0,
                                   employees: 0, employees_with_confirmed_orders: 0, confirmed_meals: 0,
                                   monthly_subsidized_meals: 0, monthly_quota_meals: nil, monthly_available_meals: nil)

    expect(snapshot.participation_percent).to be_nil
    expect(snapshot.average_confirmed_meals_per_employee).to be_nil
    expect(snapshot.monthly_utilization_percent).to be_nil
    snapshot.eligible_with_confirmed_orders = 1
    expect(snapshot).not_to be_valid
    expect(snapshot.errors[:eligible_with_confirmed_orders]).to be_present
  end

  it "distinguishes a real zero-activity month from a fully used quota" do
    empty = historical_snapshot(company:, month: month.prev_month, confirmed_orders: 0, confirmed_meals: 0,
                                monthly_subsidized_meals: 0, employees_with_confirmed_orders: 0,
                                eligible_with_confirmed_orders: 0, eligible_without_orders: 8,
                                monthly_available_meals: 160, monthly_unused_closed_meals: 160,
                                company_subsidy_amount: 0)
    full = historical_snapshot(company:, month:, confirmed_meals: 160, monthly_subsidized_meals: 160,
                               monthly_available_meals: 0, monthly_unused_closed_meals: 0)

    expect(empty.monthly_utilization_percent).to eq(0)
    expect(full.monthly_utilization_percent).to eq(100)
  end

  it "prevents silent changes to closed snapshots and audits an explicit correction" do
    snapshot = historical_snapshot(company:, month:)

    expect(snapshot.update(monthly_quota_meals: 200)).to be false
    snapshot.reload
    expect do
      BenefitUsageSnapshotCorrection.new(snapshot:, user: users(:admin), reason: "Ajuste validado",
                                         changes: { monthly_quota_meals: 200 }).call
    end.to change(AuditLog, :count).by(1)
    expect(snapshot.reload.monthly_quota_meals).to eq(200)
    expect(AuditLog.last.changeset).to include("reason" => "Ajuste validado")
  end

  it "does not invent a record for a month without a snapshot" do
    expect(described_class.find_by(company:, month:)).to be_nil
  end
end
