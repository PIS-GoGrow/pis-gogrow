# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("lib/ibp041/local_snapshot_qa")

RSpec.describe Ibp041::LocalSnapshotQa do
  let(:company) { companies(:gogrow) }
  let(:service) { described_class.new(company_id: company.id) }

  before { allow(service).to receive(:local_database?).and_return(true) }

  it "loads September and October once without changing operational data" do
    before_counts = [ Order.count, Benefit.count, Consumer.count, OrderBenefit.count ]

    first = service.load!
    second = service.load!

    expect(first).to eq(second)
    expect(first.map { it[:month] }).to eq(%w[2026-09 2026-10])
    september, october = BenefitUsageMonthlySnapshot.where(company:).order(:month).to_a
    expect([ september.employees, september.eligible_employees, september.confirmed_meals,
             september.monthly_quota_meals, september.company_subsidy_amount ])
      .to eq([ 38, 36, 28, 720, BigDecimal("4200.00") ])
    expect([ october.employees, october.eligible_employees, october.confirmed_meals,
             october.monthly_quota_meals, october.company_subsidy_amount ])
      .to eq([ 40, 38, 44, 760, BigDecimal("6600.00") ])
    expect([ september, october ].map(&:status)).to eq(%w[closed closed])
    expect([ september, october ].map(&:fictional?)).to eq([ true, true ])
    expect(september.captured_at).to eq(Time.zone.local(2026, 9, 30, 23, 55))
    expect(october.captured_at).to eq(Time.zone.local(2026, 10, 31, 23, 55))
    expect([ september.monthly_unused_closed_meals, october.monthly_unused_closed_meals ]).to eq([ 690, 716 ])
    expect([ september.closed_at, october.closed_at ]).to eq([ september.captured_at, october.captured_at ])
    expect(october.unavailable_reasons).to be_empty
    expect([ Order.count, Benefit.count, Consumer.count, OrderBenefit.count ]).to eq(before_counts)
  end

  it "upgrades only the two unchanged local fictional captures, atomically and idempotently" do
    september = ibp_041_incomplete_snapshot(company:)
    october = ibp_041_incomplete_snapshot(company:, key: "2026-10")
    before_counts = [ Order.count, Benefit.count, Consumer.count ]

    service.upgrade!
    service.upgrade!

    expect([ september.reload, october.reload ].map(&:status)).to eq(%w[closed closed])
    expect([ september, october ].map(&:monthly_unused_closed_meals)).to eq([ 690, 716 ])
    expect(BenefitUsageMonthlySnapshot.where(company:).count).to eq(2)
    expect([ Order.count, Benefit.count, Consumer.count ]).to eq(before_counts)
  end

  it "refuses an altered fictional capture without upgrading either month" do
    september = ibp_041_incomplete_snapshot(company:)
    october = ibp_041_incomplete_snapshot(company:, key: "2026-10")
    october.update!(confirmed_meals: 45)

    expect { service.upgrade! }.to raise_error(/no coinciden/)
    expect(september.reload).to be_incomplete
    expect(october.reload).to be_incomplete
  end

  it "refuses to upgrade a real snapshot or run without the local database guard" do
    september = ibp_041_incomplete_snapshot(company:)
    historical_snapshot(company:, month: Date.new(2026, 10, 1), fictional: false)

    expect { service.upgrade! }.to raise_error(/fotografía real/)
    expect(september.reload).to be_incomplete

    allow(service).to receive(:local_database?).and_return(false)
    expect { service.upgrade! }.to raise_error(/no es la base local/)
  end

  it "uses the existing historical comparison path" do
    service.load!

    history = AdminBenefitUsageHistory.new(company:, month: Date.new(2026, 10, 1)).to_h

    expect(history.dig(:period, :source)).to eq("historical_snapshot")
    expect(history.dig(:metrics, :participation_percent)).to eq(BigDecimal("42.11"))
    changes = history[:comparisons].last[:changes]
    expect(changes.dig(:confirmed_meals, :difference)).to eq(16)
    expect(changes.dig(:monthly_quota_meals, :difference)).to eq(40)
    expect(changes.dig(:eligible_with_confirmed_orders, :difference)).to eq(4)
    expect(changes.dig(:participation_percent, :difference_points)).to eq(BigDecimal("8.77"))
    expect(changes.dig(:company_subsidy_amount, :difference)).to eq(BigDecimal("2400.00"))
  end

  it "refuses a real snapshot before inserting either month" do
    historical_snapshot(company:, month: Date.new(2026, 10, 1), fictional: false)

    expect { service.load! }.to raise_error(/fotografía real/)
    expect(BenefitUsageMonthlySnapshot.where(company:).count).to eq(1)
    expect(BenefitUsageMonthlySnapshot.find_by(company:, month: Date.new(2026, 9, 1))).to be_nil
  end

  it "refuses a different fictional snapshot instead of presenting it as this scenario" do
    historical_snapshot(company:, month: Date.new(2026, 10, 1), status: :incomplete, closed_at: nil,
                        captured_at: Time.zone.local(2026, 10, 31, 23, 55))

    expect { service.load! }.to raise_error(/fotografía ficticia diferente/)
    expect(BenefitUsageMonthlySnapshot.where(company:).count).to eq(1)
    expect(service.remove!).to eq(0)
  end

  it "removes only these two fictional snapshots for the selected company" do
    service.load!
    other = Company.create!(name: "Otra empresa")
    historical_snapshot(company: other, month: Date.new(2026, 9, 1))
    historical_snapshot(company:, month: Date.new(2026, 8, 1))
    before_counts = [ Order.count, Benefit.count, Consumer.count ]

    expect(service.remove!).to eq(2)
    expect(service.remove!).to eq(0)
    expect(BenefitUsageMonthlySnapshot.where(company:).pluck(:month)).to eq([ Date.new(2026, 8, 1) ])
    expect(BenefitUsageMonthlySnapshot.where(company: other).count).to eq(1)
    expect([ Order.count, Benefit.count, Consumer.count ]).to eq(before_counts)
  end

  it "rejects production and staging before querying or writing" do
    allow(service).to receive(:local_database?).and_call_original
    %w[production staging].each do |environment|
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(environment))
      expect { service.load! }.to raise_error(/no es la base local/)
    end
    expect(BenefitUsageMonthlySnapshot.where(company:).count).to eq(0)
  end

  it "rejects the test database even when the Rails environment is mislabeled development" do
    allow(service).to receive(:local_database?).and_call_original
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("IBP041_QA_LOCAL_DB").and_return("rails_inertia_base_development@db")

    expect { service.load! }.to raise_error(/no es la base local/)
    expect(BenefitUsageMonthlySnapshot.where(company:).count).to eq(0)
  end

  it "rejects a remote database URL even when development and the local flag are set" do
    allow(service).to receive(:local_database?).and_call_original
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("IBP041_QA_LOCAL_DB").and_return("rails_inertia_base_development@db")
    allow(ENV).to receive(:[]).with("DATABASE_URL").and_return("postgresql://remote.example.invalid/shared")

    expect { service.load! }.to raise_error(/no es la base local/)
    expect(BenefitUsageMonthlySnapshot.where(company:).count).to eq(0)
  end
end
