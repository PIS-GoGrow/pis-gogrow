# frozen_string_literal: true

abort "Run with RAILS_ENV=test" unless Rails.env.test?

SCALES = { small: [ 20, 200 ], medium: [ 200, 4_000 ], large: [ 1_000, 20_000 ] }.freeze
RUNS = 10

def measure
  queries = []
  subscriber = lambda do |event|
    payload = event.payload
    queries << payload[:sql] unless payload[:cached] || %w[SCHEMA TRANSACTION].include?(payload[:name])
  end
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { yield }
  { milliseconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1_000, queries: }
end

def percentile(samples, fraction)
  sorted = samples.sort
  sorted[(sorted.size * fraction).ceil - 1].round(2)
end

def seed_scale(label, employee_count, order_count, current_month)
  now = Time.current
  company = Company.create!(name: "Benchmark #{label}")
  administrator = User.create!(name: "Administrador sintético", email: "benchmark-admin-#{label}@example.test",
                               password: "synthetic-password-123")
  Admin.create!(user: administrator, company:)
  configuration = BenefitConfiguration.create!(company:, created_by: administrator, name: "Subsidio sintético",
                                               subsidy_percentage: 50)
  MonthlyBenefit.insert!({ benefit_configuration_id: configuration.id, effective_from: current_month << 3,
                           limit: 20, max_price: 500, created_at: now, updated_at: now })

  digest = BCrypt::Password.create("synthetic-password-123").to_s
  user_ids = User.insert_all!(Array.new(employee_count) do |index|
    { name: "Empleado sintético #{index}", email: "benchmark-#{label}-#{index}@example.test",
      password_digest: digest, created_at: now, updated_at: now }
  end).rows.flatten
  consumer_ids = Consumer.insert_all!(user_ids.map do |user_id|
    { user_id:, company_id: company.id, onboarding_date: current_month << 4,
      created_at: now, updated_at: now }
  end).rows.flatten

  months = 3.downto(0).map { current_month << it }
  slots = consumer_ids.product(months)
  grant_ids = Benefit.insert_all!(slots.map do |consumer_id, month|
    { consumer_id:, benefit_configuration_id: configuration.id, amount: 20, percentage: 50,
      due_date: month.end_of_month, status: month == current_month ? 0 : 1,
      created_at: now, updated_at: now }
  end).rows.flatten

  orders_per_slot, remainder = order_count.divmod(slots.size)
  order_rows = slots.each_with_index.flat_map do |(consumer_id, month), index|
    Array.new(orders_per_slot + (index < remainder ? 1 : 0)) do
      { consumer_id:, delivery_date: month, status: Order.statuses.fetch("confirmed"), amount: 1,
        price: 300, discounted_price: 150, delivery_method: Order.delivery_methods.fetch("office"),
        selected_options: [], created_at: now, updated_at: now }
    end
  end
  order_ids = order_rows.each_slice(1_000).flat_map { Order.insert_all!(it).rows.flatten }
  grant_for_slot = slots.zip(grant_ids).to_h
  uses = order_rows.zip(order_ids).map do |order, order_id|
    { order_id:, benefit_id: grant_for_slot.fetch([ order.fetch(:consumer_id), order.fetch(:delivery_date) ]),
      benefit_used: 1, created_at: now, updated_at: now }
  end
  uses.each_slice(1_000) { OrderBenefit.insert_all!(it) }

  [ company, administrator ]
end

def benchmark_scale(label, employee_count, order_count)
  ActiveRecord::Base.transaction do
    current_month = Date.current.beginning_of_month
    company, administrator = seed_scale(label, employee_count, order_count, current_month)
    session_id = Session.insert!({ user_id: administrator.id, role: Session.roles.fetch("admin"),
                                   created_at: Time.current, updated_at: Time.current }).rows.first.first
    cookie_jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
    cookie_jar.signed[:session_token] = session_id
    browser = ActionDispatch::Integration::Session.new(Rails.application)
    browser.cookies[:session_token] = cookie_jar[:session_token]

    [ [ :current, current_month ], [ :historical, current_month.prev_month ] ].each do |kind, month|
      path = "/rrhh/uso-beneficio?month=#{month.strftime('%Y-%m')}"
      2.times do
        AdminBenefitUsageStats.new(company:, month:).to_h
        browser.get(path, headers: { "Accept" => "application/json" })
        raise "GET failed: #{browser.response.status}" unless browser.response.status == 200
      end

      service = Array.new(RUNS) { measure { AdminBenefitUsageStats.new(company:, month:).to_h } }
      endpoint = Array.new(RUNS) do
        measure do
          browser.get(path, headers: { "Accept" => "application/json" })
          raise "GET failed: #{browser.response.status}" unless browser.response.status == 200
        end
      end
      health = Array.new(RUNS) do
        measure do
          browser.get("/up")
          raise "Health check failed: #{browser.response.status}" unless browser.response.status == 200
        end
      end
      repeated = service.first.fetch(:queries).tally.select { |_sql, count| count > 1 }
      puts JSON.generate(
        scale: label, month: kind, employees: employee_count, orders: order_count,
        sql_count: percentile(service.map { it.fetch(:queries).size }, 0.5),
        engine_median_ms: percentile(service.map { it.fetch(:milliseconds) }, 0.5),
        engine_p95_ms: percentile(service.map { it.fetch(:milliseconds) }, 0.95),
        get_sql_count: percentile(endpoint.map { it.fetch(:queries).size }, 0.5),
        get_median_ms: percentile(endpoint.map { it.fetch(:milliseconds) }, 0.5),
        get_p95_ms: percentile(endpoint.map { it.fetch(:milliseconds) }, 0.95),
        health_median_ms: percentile(health.map { it.fetch(:milliseconds) }, 0.5),
        repeated_sql_shapes: repeated.size, repeated_sql_executions: repeated.values.sum
      )
    end
    raise ActiveRecord::Rollback
  end
end

SCALES.each do |label, (employee_count, order_count)|
  next if label == :large && ENV["BENCHMARK_LARGE"] != "1"

  benchmark_scale(label, employee_count, order_count)
end
