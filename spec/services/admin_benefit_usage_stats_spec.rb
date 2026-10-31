# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminBenefitUsageStats do
  let(:company) { companies(:gogrow) }
  let(:month) { Date.new(2032, 4, 17) }
  let(:stats) { described_class.new(company:, month:).to_h }

  def insert_order(status: :confirmed, amount: 1, consumer: consumers(:one), delivery_date: month,
                   schedule: nil, discounted_price: 300)
    result = Order.insert!({
      consumer_id: consumer.id,
      schedule_id: schedule&.id,
      delivery_date:,
      status: Order.statuses.fetch(status.to_s),
      amount:,
      price: 300 * amount,
      discounted_price:,
      delivery_method: Order.delivery_methods.fetch("office"),
      selected_options: [],
      created_at: Time.current,
      updated_at: Time.current
    })
    Order.find(result.rows.first.first)
  end

  def apply_benefit(order, benefit, units)
    OrderBenefit.insert!({ order_id: order.id, benefit_id: benefit.id, benefit_used: units,
                           created_at: Time.current, updated_at: Time.current })
  end

  def grant_monthly(consumer:, configuration: benefit_configurations(:monthly), amount: 20,
                    due_date: month.end_of_month, status: :future)
    result = Benefit.insert!({ consumer_id: consumer.id, benefit_configuration_id: configuration.id,
                               amount:, percentage: 50, due_date:,
                               status: Benefit.statuses.fetch(status.to_s),
                               created_at: Time.current, updated_at: Time.current })
    Benefit.find(result.rows.first.first)
  end

  def create_monthly_configuration(effective_from:, limit:, for_company: company)
    configuration = BenefitConfiguration.create!(company: for_company, created_by: users(:admin),
                                                 name: "Subsidio mensual", subsidy_percentage: 50)
    MonthlyBenefit.insert!({ benefit_configuration_id: configuration.id, effective_from:, limit:,
                             max_price: 500, created_at: Time.current, updated_at: Time.current })
    configuration
  end

  def warning_codes
    stats[:warnings].pluck(:code)
  end

  it "counts orders separately from meals and normalizes the month" do
    insert_order(amount: 3, discounted_price: 900)

    expect(stats[:period]).to eq(month: Date.new(2032, 4, 1))
    expect(stats[:orders]).to eq(confirmed_orders: 1, confirmed_meals: 3, pending_orders: 0, pending_meals: 0)
    expect(stats[:benefits]).to include(monthly_subsidized_meals: 0, confirmed_meals_without_monthly_subsidy: 3)
  end

  it "separates pending orders and excludes cancelled and rejected orders from confirmed consumption" do
    insert_order(status: :confirmed, amount: 2, discounted_price: 600)
    insert_order(status: :pending, amount: 3, discounted_price: 900)
    insert_order(status: :cancelled, amount: 4, discounted_price: 1200)
    insert_order(status: :rejected, amount: 5, discounted_price: 1500)

    expect(stats[:orders]).to eq(confirmed_orders: 1, confirmed_meals: 2, pending_orders: 1, pending_meals: 3)
  end

  it "uses delivery_date before the schedule date and excludes other months" do
    schedule = Schedule.insert!({ menu_id: menus(:milanesa).id, date: month.next_month,
                                  created_at: Time.current, updated_at: Time.current })
    scheduled = Schedule.find(schedule.rows.first.first)
    insert_order(schedule: scheduled, delivery_date: month, discounted_price: 300)
    insert_order(delivery_date: month.next_month, discounted_price: 300)

    expect(stats[:orders][:confirmed_orders]).to eq(1)
  end

  it "uses the schedule date when the delivery date is absent" do
    schedule = Schedule.insert!({ menu_id: menus(:milanesa).id, date: month,
                                  created_at: Time.current, updated_at: Time.current })
    insert_order(schedule: Schedule.find(schedule.rows.first.first), delivery_date: nil, discounted_price: 300)

    expect(stats[:orders][:confirmed_meals]).to eq(1)
  end

  it "keeps a delivery-dated order after its schedule is deleted" do
    inserted = Schedule.insert!({ menu_id: menus(:milanesa).id, date: month.next_month,
                                  created_at: Time.current, updated_at: Time.current })
    schedule = Schedule.find(inserted.rows.first.first)
    selected = insert_order(schedule:, delivery_date: month, amount: 2, discounted_price: 600)
    insert_order(schedule:, delivery_date: month.next_month, amount: 4, discounted_price: 1200)
    schedule.destroy!

    expect(selected.reload.schedule_id).to be_nil
    expect(stats[:orders]).to include(confirmed_orders: 1, confirmed_meals: 2)
  end

  it "counts monthly benefit units once when a special benefit also applies" do
    order = insert_order(amount: 3, discounted_price: 300)
    special = Benefit.create!(consumer: consumers(:one), benefit_configuration: benefit_configurations(:gift),
                              percentage: 50, amount: 10)
    apply_benefit(order, benefits(:monthly), 2)
    apply_benefit(order, special, 2)

    expect(stats[:benefits]).to include(monthly_subsidized_meals: 2, confirmed_meals_without_monthly_subsidy: 1)
    expect(stats[:orders][:confirmed_meals]).to eq(3)
  end

  it "only counts monthly benefit units on confirmed orders" do
    confirmed = insert_order(amount: 2, discounted_price: 300)
    pending = insert_order(status: :pending, discounted_price: 150)
    rejected = insert_order(status: :rejected, discounted_price: 150)
    apply_benefit(confirmed, benefits(:monthly), 2)
    apply_benefit(pending, benefits(:monthly), 1)
    apply_benefit(rejected, benefits(:monthly), 1)

    expect(stats[:benefits][:monthly_subsidized_meals]).to eq(2)
  end

  it "restricts every count to the company's current consumers" do
    other_company = Company.create!(name: "Otra empresa", address: "Rincón 500")
    other_user = User.create!(name: "Otro empleado", email: "otro@example.com", password: "secret-password-123")
    other_consumer = Consumer.create!(user: other_user, company: other_company)
    insert_order(consumer: other_consumer, amount: 4, discounted_price: 1200)
    insert_order(consumer: consumers(:one), discounted_price: 300)

    expect(stats[:orders][:confirmed_meals]).to eq(1)
    expect(stats[:employees][:current_employees]).to eq(2)
    expect(stats[:employees][:current_employees_with_confirmed_orders]).to eq(1)
  end

  it "counts current employees with any order, confirmed orders, and no orders" do
    insert_order(status: :pending, consumer: consumers(:one), discounted_price: 300)
    insert_order(status: :cancelled, consumer: consumers(:one), discounted_price: 300)

    expect(stats[:employees]).to include(
      current_employees: 2,
      current_employees_with_orders: 1,
      current_employees_with_confirmed_orders: 0,
      current_employees_without_orders: 1
    )
    expect(warning_codes).to include("employee_counts_use_current_roster")
  end

  it "counts an employee with multiple confirmed orders only once" do
    insert_order(consumer: consumers(:one), discounted_price: 300)
    insert_order(consumer: consumers(:one), discounted_price: 300)

    expect(stats[:employees][:current_employees_with_confirmed_orders]).to eq(1)
  end

  it "returns zero for calculable indicators in a month without activity" do
    expect(stats[:orders]).to eq(confirmed_orders: 0, confirmed_meals: 0, pending_orders: 0, pending_meals: 0)
    expect(stats[:benefits]).to include(monthly_subsidized_meals: 0, confirmed_meals_without_monthly_subsidy: 0)
    expect(stats[:employees][:current_employees_without_orders]).to eq(2)
  end

  it "does not invent the unsubsidized count for a historical discount without benefit records" do
    insert_order(amount: 2, discounted_price: 300)

    expect(stats[:benefits][:monthly_subsidized_meals]).to be_nil
    expect(stats[:benefits][:confirmed_meals_without_monthly_subsidy]).to be_nil
    expect(warning_codes).to include("historical_discounts_without_benefit_records")
  end

  it "flags monthly benefit records that exceed the order quantity" do
    order = insert_order(amount: 1, discounted_price: 150)
    apply_benefit(order, benefits(:monthly), 2)

    expect(stats[:benefits][:monthly_subsidized_meals]).to be_nil
    expect(stats[:benefits][:confirmed_meals_without_monthly_subsidy]).to be_nil
    expect(warning_codes).to include("monthly_benefit_units_exceed_order_amount")
  end

  it "does not treat duplicate historical monthly grants as trustworthy eligibility or quota" do
    allow(Date).to receive(:current).and_return(Date.new(2032, 4, 17))
    grant_monthly(consumer: consumers(:one))
    grant_monthly(consumer: consumers(:one))
    grant_monthly(consumer: consumers(:other))

    expect(Benefit.monthly.where(consumer: consumers(:one), due_date: month.end_of_month).count).to eq(2)
    expect(stats[:employees][:eligibility]).to eq(eligible: 1, ineligible: 0, unknown: 1)
    expect(stats[:benefits]).to include(known_eligible_monthly_quota_meals: 20, monthly_quota_meals: nil)
    expect(stats[:employees][:participation_percent]).to be_nil
    expect(warning_codes).to include("eligibility_unknown")
  end

  it "rejects a second current monthly grant for the same configuration" do
    duplicate = Benefit.new(consumer: consumers(:one), benefit_configuration: benefit_configurations(:monthly),
                            amount: 20, percentage: 50, due_date: month.end_of_month, status: :current)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:base]).to include("el cliente ya tiene un beneficio mensual")
  end

  it "rejects a negative monthly benefit use instead of counting it as consumption" do
    order = insert_order(discounted_price: 300)
    apply_benefit(order, benefits(:monthly), -1)

    expect(stats[:benefits][:monthly_subsidized_meals]).to be_nil
    expect(warning_codes).to include("monthly_benefit_units_exceed_order_amount")
  end

  it "does not trust a monthly benefit belonging to another consumer on the order" do
    order = insert_order(discounted_price: 150)
    foreign_grant = grant_monthly(consumer: consumers(:other), status: :expired)
    apply_benefit(order, foreign_grant, 1)

    expect(stats[:benefits][:monthly_subsidized_meals]).to be_nil
    expect(stats[:benefits][:monthly_available_meals]).to be_nil
    expect(stats[:benefits][:confirmed_meals_without_monthly_subsidy]).to be_nil
    expect(warning_codes).to include("benefit_consumer_mismatch")
  end

  it "does not treat another consumer's pending benefit as a valid reservation" do
    order = insert_order(status: :pending, discounted_price: 150)
    foreign_grant = grant_monthly(consumer: consumers(:other), status: :expired)
    apply_benefit(order, foreign_grant, 1)

    expect(stats[:benefits][:monthly_pending_reserved_meals]).to be_nil
    expect(warning_codes).to include("benefit_consumer_mismatch")
  end

  it "flags a benefit from another company's consumer linked to the order" do
    other_company = Company.create!(name: "Otra empresa", address: "Rincón 500")
    other_user = User.create!(name: "Otro empleado", email: "otro-vinculo@example.test", password: "secret-password-123")
    other_consumer = Consumer.create!(user: other_user, company: other_company)
    benefit = grant_monthly(consumer: other_consumer, status: :expired)
    order = insert_order(discounted_price: 150)
    apply_benefit(order, benefit, 1)

    expect(stats[:benefits][:monthly_subsidized_meals]).to be_nil
    expect(warning_codes).to include("benefit_consumer_mismatch")
  end

  context "when the selected month is current" do
    let(:month) { Date.current }

    before { allow(Date).to receive(:current).and_return(Date.new(2032, 4, 17)) }

    it "classifies recorded monthly grants and uses their configured quota" do
      grant_monthly(consumer: consumers(:one))
      grant_monthly(consumer: consumers(:other))

      expect(stats[:employees][:eligibility]).to eq(eligible: 2, ineligible: 0, unknown: 0)
      expect(stats[:benefits]).to include(known_eligible_monthly_quota_meals: 40,
                                         monthly_quota_meals: 40, monthly_available_meals: 40)
      expect(stats[:employees][:participation_percent]).to eq(0.0)
      expect(stats[:employees][:eligible_without_orders]).to eq(2)
    end

    it "separates full and partial confirmed use from pending reservations" do
      first_grant = grant_monthly(consumer: consumers(:one))
      second_grant = grant_monthly(consumer: consumers(:other))
      full = insert_order(consumer: consumers(:one), amount: 20, discounted_price: 3000)
      partial = insert_order(consumer: consumers(:other), amount: 2, discounted_price: 300)
      pending = insert_order(consumer: consumers(:other), status: :pending, amount: 3, discounted_price: 450)
      apply_benefit(full, first_grant, 20)
      apply_benefit(partial, second_grant, 2)
      apply_benefit(pending, second_grant, 3)

      expect(stats[:benefits]).to include(monthly_subsidized_meals: 22,
                                         monthly_pending_reserved_meals: 3,
                                         monthly_available_meals: 15)
      expect(stats[:employees][:participation_percent]).to eq(100.0)
    end

    it "does not count a pending order as participation or as no order" do
      grant = grant_monthly(consumer: consumers(:one))
      grant_monthly(consumer: consumers(:other))
      pending = insert_order(consumer: consumers(:one), status: :pending, discounted_price: 150)
      apply_benefit(pending, grant, 1)

      expect(stats[:employees][:participation_percent]).to eq(0.0)
      expect(stats[:employees][:eligible_without_orders]).to eq(1)
      expect(stats[:benefits][:monthly_pending_reserved_meals]).to eq(1)
    end

    it "uses onboarding after the month as evidence of ineligibility without a conflicting grant" do
      grant_monthly(consumer: consumers(:one))
      consumers(:other).update_columns(onboarding_date: month.next_month)

      expect(stats[:employees][:eligibility]).to eq(eligible: 1, ineligible: 1, unknown: 0)
      expect(stats[:benefits][:monthly_quota_meals]).to eq(20)
    end

    it "leaves eligibility and participation unknown without a grant or exclusion evidence" do
      grant_monthly(consumer: consumers(:one))

      expect(stats[:employees][:eligibility]).to eq(eligible: 1, ineligible: 0, unknown: 1)
      expect(stats[:employees][:participation_percent]).to be_nil
      expect(stats[:benefits][:monthly_quota_meals]).to be_nil
      expect(warning_codes).to include("eligibility_unknown")
    end

    it "does not guess a reservation from a pending historical discount without benefit records" do
      grant_monthly(consumer: consumers(:one))
      grant_monthly(consumer: consumers(:other))
      insert_order(status: :pending, discounted_price: 150)

      expect(stats[:benefits][:monthly_pending_reserved_meals]).to be_nil
      expect(stats[:benefits][:monthly_available_meals]).to be_nil
      expect(warning_codes).to include("pending_discounts_without_benefit_records")
    end
  end

  it "accepts an expired grant for a historical month but leaves the full historical roster unknown" do
    historical_month = Date.new(2026, 9, 15)
    configuration = create_monthly_configuration(effective_from: historical_month.beginning_of_month, limit: 7)
    grant_monthly(consumer: consumers(:one), configuration:, amount: 7,
                  due_date: historical_month.end_of_month, status: :expired)
    result = described_class.new(company:, month: historical_month).to_h

    expect(result[:employees][:eligibility]).to eq(eligible: 1, ineligible: 0, unknown: 1)
    expect(result[:benefits][:known_eligible_monthly_quota_meals]).to eq(7)
    expect(result[:benefits][:monthly_unused_closed_meals]).to be_nil
    expect(result[:employees][:participation_percent]).to be_nil
    expect(result[:warnings].pluck(:code)).to include("historical_roster_incomplete")
  end

  it "uses the grant and configured limit of each month when the base subsidy changes" do
    april = Date.new(2032, 4, 15)
    may = april.next_month
    old_configuration = create_monthly_configuration(effective_from: april.beginning_of_month, limit: 6)
    new_configuration = create_monthly_configuration(effective_from: may.beginning_of_month, limit: 9)
    grant_monthly(consumer: consumers(:one), configuration: old_configuration, amount: 6,
                  due_date: april.end_of_month, status: :expired)
    grant_monthly(consumer: consumers(:one), configuration: new_configuration, amount: 9,
                  due_date: may.end_of_month, status: :future)

    expect(described_class.new(company:, month: april).to_h[:benefits][:known_eligible_monthly_quota_meals]).to eq(6)
    expect(described_class.new(company:, month: may).to_h[:benefits][:known_eligible_monthly_quota_meals]).to eq(9)
  end

  it "separates confirmed and pending uses but leaves the closing balance unknown" do
    historical_month = Date.new(2026, 9, 15)
    configuration = create_monthly_configuration(effective_from: historical_month.beginning_of_month, limit: 7)
    grant = grant_monthly(consumer: consumers(:one), configuration:, amount: 7,
                          due_date: historical_month.end_of_month, status: :expired)
    confirmed = insert_order(delivery_date: historical_month, amount: 2, discounted_price: 300)
    pending = insert_order(delivery_date: historical_month, status: :pending, amount: 3, discounted_price: 450)
    cancelled = insert_order(delivery_date: historical_month, status: :cancelled, discounted_price: 150)
    rejected = insert_order(delivery_date: historical_month, status: :rejected, discounted_price: 150)
    apply_benefit(confirmed, grant, 2)
    apply_benefit(pending, grant, 3)
    apply_benefit(cancelled, grant, 1)
    apply_benefit(rejected, grant, 1)
    result = described_class.new(company:, month: historical_month).to_h

    expect(result[:benefits]).to include(monthly_subsidized_meals: 2,
                                         monthly_pending_reserved_meals: 3,
                                         monthly_unused_closed_meals: nil)
    expect(result[:warnings].pluck(:code)).to include("historical_status_at_close_unavailable")
  end

  it "does not include another company's grant in eligibility or quota" do
    other_company = Company.create!(name: "Otra empresa", address: "Rincón 500")
    other_user = User.create!(name: "Otro empleado", email: "otro-beneficio@example.com", password: "secret-password-123")
    other_consumer = Consumer.create!(user: other_user, company: other_company)
    configuration = create_monthly_configuration(effective_from: month.beginning_of_month, limit: 11,
                                                  for_company: other_company)
    grant_monthly(consumer: other_consumer, configuration:, amount: 11)

    expect(stats[:employees][:eligibility][:eligible]).to eq(0)
    expect(stats[:benefits][:known_eligible_monthly_quota_meals]).to eq(0)
  end

  describe "company subsidy amount" do
    it "adds the decimal discount once for a confirmed order with monthly and special benefits" do
      order = insert_order(amount: 2, discounted_price: "225.55")
      special = Benefit.create!(consumer: consumers(:one), benefit_configuration: benefit_configurations(:gift),
                                percentage: 50, amount: 10)
      apply_benefit(order, benefits(:monthly), 1)
      apply_benefit(order, special, 1)

      expect(stats[:benefits][:company_subsidy_amount]).to eq(BigDecimal("374.45"))
    end

    it "returns zero without discounts or activity and excludes nonconfirmed orders" do
      insert_order(discounted_price: 300)
      insert_order(status: :pending, discounted_price: 150)
      insert_order(status: :cancelled, discounted_price: 150)
      insert_order(status: :rejected, discounted_price: 150)

      expect(stats[:benefits][:company_subsidy_amount]).to eq(BigDecimal("0"))
      expect(described_class.new(company:, month: month.next_month).to_h[:benefits][:company_subsidy_amount]).to eq(BigDecimal("0"))
    end

    it "returns nil for missing monetary amounts" do
      order = insert_order(discounted_price: 150)
      order.update_columns(price: nil)

      expect(stats[:benefits][:company_subsidy_amount]).to be_nil
      expect(warning_codes).to include("company_subsidy_amount_unreliable")
    end

    it "returns nil when the discounted price exceeds the original price" do
      insert_order(discounted_price: 400)

      expect(stats[:benefits][:company_subsidy_amount]).to be_nil
      expect(warning_codes).to include("company_subsidy_amount_unreliable")
    end

    [
      [ :discounted_price, nil ],
      [ :price, -1 ],
      [ :discounted_price, -1 ]
    ].each do |field, invalid_value|
      it "rejects #{field} #{invalid_value.inspect} without reporting a partial subsidy total" do
        insert_order(discounted_price: 200)
        invalid = insert_order(discounted_price: 150)
        invalid.update_columns(field => invalid_value)

        expect(stats[:benefits][:company_subsidy_amount]).to be_nil
        expect(warning_codes).to include("company_subsidy_amount_unreliable")
        expect(stats.dig(:trends, :months).last[:company_subsidy_amount]).to be_nil
      end
    end

    it "does not include another company's discount" do
      other_company = Company.create!(name: "Otra empresa", address: "Rincón 500")
      other_user = User.create!(name: "Otro empleado", email: "otra-inversion@example.com", password: "secret-password-123")
      other_consumer = Consumer.create!(user: other_user, company: other_company)
      insert_order(consumer: other_consumer, discounted_price: 50)
      insert_order(discounted_price: 200)

      expect(stats[:benefits][:company_subsidy_amount]).to eq(BigDecimal("100"))
    end
  end

  describe "trends and anomalies" do
    let(:month) { Date.current.prev_month }

    before { allow(Date).to receive(:current).and_return(Date.new(2032, 6, 17)) }

    it "keeps four monthly absolute values and compares adjacent complete months" do
      [ 4, 8, 10, 12 ].each_with_index do |meals, index|
        insert_order(delivery_date: month << (3 - index), amount: meals, discounted_price: meals * 150)
      end

      series = stats.dig(:trends, :months)
      expect(series.map { it[:month] }).to eq(3.downto(0).map { month.beginning_of_month << it })
      expect(series.map { it[:confirmed_meals] }).to eq([ 4, 8, 10, 12 ])
      expect(series.map { it[:company_subsidy_amount] }).to eq([ 600, 1200, 1500, 1800 ])
      expect(series[1].dig(:changes, :confirmed_meals)).to eq(reference: 4, difference: 4, percent: BigDecimal("100"))
      expect(series.last.dig(:changes, :confirmed_orders)).to eq(reference: 1, difference: 0, percent: BigDecimal("0"))
    end

    [
      [ :confirmed_meals, 100, 129, false ],
      [ :confirmed_meals, 100, 130, true ],
      [ :confirmed_meals, 9, 18, false ],
      [ :confirmed_meals, 10, 13, true ],
      [ :monthly_subsidized_meals, 100, 129, false ],
      [ :monthly_subsidized_meals, 100, 130, true ],
      [ :monthly_subsidized_meals, 9, 18, false ],
      [ :monthly_subsidized_meals, 10, 13, true ]
    ].each do |indicator, reference, current, anomalous|
      it "applies the anomaly boundary to #{indicator}: #{reference} to #{current}" do
        earlier = insert_order(delivery_date: month.prev_month, amount: reference, discounted_price: 300 * reference)
        latest = insert_order(amount: current, discounted_price: 300 * current)
        if indicator == :monthly_subsidized_meals
          configuration = create_monthly_configuration(effective_from: month.prev_month.beginning_of_month,
                                                       limit: 200)
          earlier_grant = grant_monthly(consumer: consumers(:one), configuration:,
                                        due_date: month.prev_month.end_of_month, status: :expired, amount: 200)
          latest_grant = grant_monthly(consumer: consumers(:one), configuration:,
                                       due_date: month.end_of_month, status: :expired, amount: 200)
          apply_benefit(earlier, earlier_grant, reference)
          apply_benefit(latest, latest_grant, current)
        end

        matches = stats[:anomalies].select { it[:indicator] == indicator.to_s && it[:month] == month.beginning_of_month }
        expect(matches.any?).to be(anomalous)
      end
    end

    it "orders October through January across a year boundary and leaves January open" do
      january = Date.new(2032, 1, 17)
      allow(Date).to receive(:current).and_return(january)
      [ 2, 3, 4, 5 ].each_with_index do |meals, index|
        insert_order(delivery_date: january.beginning_of_month << (3 - index), amount: meals,
                     discounted_price: 300 * meals)
      end
      insert_order(delivery_date: january.next_month, amount: 99, discounted_price: 29_700)

      series = described_class.new(company:, month: january).to_h.dig(:trends, :months)
      expect(series.map { it[:month] }).to eq([ Date.new(2031, 10, 1), Date.new(2031, 11, 1),
                                                Date.new(2031, 12, 1), Date.new(2032, 1, 1) ])
      expect(series.map { it[:confirmed_meals] }).to eq([ 2, 3, 4, 5 ])
      expect(series.map { it[:complete] }).to eq([ true, true, true, false ])
      expect(series[2].dig(:changes, :confirmed_meals)).to eq(reference: 3, difference: 1,
                                                               percent: BigDecimal("33.33"))
      expect(series.last.dig(:changes, :confirmed_meals)).to eq(reference: 4, difference: nil, percent: nil)
    end

    it "keeps a real zero but leaves percentage change unknown when the reference is zero" do
      insert_order(discounted_price: 300)

      change = stats.dig(:trends, :months).last.dig(:changes, :confirmed_meals)
      expect(change).to eq(reference: 0, difference: 1, percent: nil)
      expect(stats[:anomalies]).to be_empty
    end

    it "does not compare an unknown monthly subsidy count as if it were zero" do
      insert_order(delivery_date: month.prev_month, discounted_price: 150)

      series = stats.dig(:trends, :months)
      expect(series[-2][:monthly_subsidized_meals]).to be_nil
      expect(series.last.dig(:changes, :monthly_subsidized_meals)).to eq(reference: nil, difference: nil, percent: nil)
      expect(warning_codes).to include("trend_monthly_subsidy_unknown")
    end

    it "does not calculate an economic variation from an invalid reference month" do
      insert_order(delivery_date: month.prev_month, discounted_price: 400)
      insert_order(discounted_price: 300)

      expect(stats.dig(:trends, :months).last.dig(:changes, :company_subsidy_amount))
        .to eq(reference: nil, difference: nil, percent: nil)
      expect(warning_codes).to include("trend_company_subsidy_unknown")
    end

    it "does not generate a meal comparison from a missing order quantity" do
      order = insert_order(delivery_date: month.prev_month, discounted_price: 300)
      order.update_columns(amount: nil)
      insert_order(discounted_price: 300)

      expect(stats.dig(:trends, :months)[-2][:confirmed_meals]).to be_nil
      expect(stats.dig(:trends, :months).last.dig(:changes, :confirmed_meals))
        .to eq(reference: nil, difference: nil, percent: nil)
      expect(stats[:anomalies]).to be_empty
      expect(warning_codes).to include("trend_confirmed_meals_unknown")
    end

    it "detects significant increases in confirmed and monthly subsidized meals" do
      configuration = create_monthly_configuration(effective_from: month.prev_month.beginning_of_month, limit: 20)
      earlier_grant = grant_monthly(consumer: consumers(:one), configuration:, due_date: month.prev_month.end_of_month,
                                    status: :expired)
      current_grant = grant_monthly(consumer: consumers(:one), configuration:, due_date: month.end_of_month,
                                    status: :expired)
      earlier = insert_order(delivery_date: month.prev_month, amount: 10, discounted_price: 1500)
      current = insert_order(amount: 14, discounted_price: 2100)
      apply_benefit(earlier, earlier_grant, 10)
      apply_benefit(current, current_grant, 14)

      expect(stats[:anomalies].map { [ it[:type], it[:indicator], it[:variation_percent] ] }).to contain_exactly(
        [ "increase", "confirmed_meals", BigDecimal("40") ],
        [ "increase", "monthly_subsidized_meals", BigDecimal("40") ]
      )
    end

    it "detects a significant decrease but ignores a one-to-two-meal change" do
      insert_order(delivery_date: month.prev_month, amount: 20, discounted_price: 6000)
      insert_order(amount: 10, discounted_price: 3000)
      insert_order(delivery_date: month << 3, discounted_price: 300)
      insert_order(delivery_date: month << 2, amount: 2, discounted_price: 600)

      expect(stats[:anomalies]).to include(include(type: "decrease", indicator: "confirmed_meals",
                                                 reference_value: 20, current_value: 10,
                                                 variation_percent: BigDecimal("-50")))
      expect(stats[:anomalies].none? { it[:month] == (month << 2).beginning_of_month }).to be(true)
    end

    it "detects a significant decrease in monthly subsidized units" do
      configuration = create_monthly_configuration(effective_from: month.prev_month.beginning_of_month, limit: 20)
      earlier_grant = grant_monthly(consumer: consumers(:one), configuration:, due_date: month.prev_month.end_of_month,
                                    status: :expired)
      current_grant = grant_monthly(consumer: consumers(:one), configuration:, due_date: month.end_of_month,
                                    status: :expired)
      earlier = insert_order(delivery_date: month.prev_month, amount: 20, discounted_price: 3000)
      current = insert_order(amount: 10, discounted_price: 1500)
      apply_benefit(earlier, earlier_grant, 20)
      apply_benefit(current, current_grant, 10)

      expect(stats[:anomalies]).to include(include(type: "decrease", indicator: "monthly_subsidized_meals",
                                                 reference_value: 20, current_value: 10,
                                                 variation_percent: BigDecimal("-50")))
    end

    it "does not generate decline alerts for an open current month" do
      allow(Date).to receive(:current).and_return(Date.new(2032, 4, 17))
      current_month = Date.current
      insert_order(delivery_date: current_month.prev_month, amount: 20, discounted_price: 6000)
      insert_order(delivery_date: current_month, discounted_price: 300)
      result = described_class.new(company:, month: current_month).to_h

      expect(result.dig(:trends, :months).last[:complete]).to be(false)
      expect(result.dig(:trends, :months).last.dig(:changes, :confirmed_meals, :percent)).to be_nil
      expect(result[:anomalies]).to be_empty
      expect(result[:warnings].pluck(:code)).to include("open_month_partial")
    end
  end
end
