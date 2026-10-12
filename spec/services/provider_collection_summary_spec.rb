# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProviderCollectionSummary do
  fixtures :users, :companies, :consumers, :providers

  let(:provider) { providers(:office_provider) }
  let(:consumer) { consumers(:one) }
  let(:menu) { provider.menus.create!(name: "Plato de prueba", description: "Con guarnición", price: 100) }

  def create_order(menu:, date:, status: :confirmed)
    schedule = menu.schedules.create!(date:, amount: 20)
    Order.create!(
      consumer:, schedule:, status:, amount: 2, price: 200, discounted_price: 100, delivery_method: :office,
      rejection_reason: status == :rejected ? :out_of_stock : nil
    )
  end

  def select_queries
    queries = []
    callback = ->(_name, _start, _finish, _id, payload) do
      queries << payload[:sql] if payload[:name] != "SCHEMA" && !payload[:cached] && payload[:sql].match?(/\A\s*SELECT/i)
    end

    ActiveRecord::Base.uncached do
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
    end

    queries
  end

  def serialize_summary(summary)
    Provider::CollectionsIndexSerializer.new({
      sales: summary.sales, sales_detail: summary.sales_detail, outstanding: summary.outstanding,
      clients: summary.clients, pending: summary.pending, history: summary.history
    }).to_h
  end

  [ 0, 1 ].each do |months_ago|
    it "keeps every account's orders in a pending group #{months_ago} months ago, including approved accounts" do
      order = create_order(menu:, date: Date.current.months_ago(months_ago).beginning_of_month + 8)
      company = order.accounts.find(&:company?)
      company.payments.create!(provider:, status: :approved)

      summary = described_class.new(provider:)
      group = summary.pending.sole

      expect(group.company_row).to be_approved
      expect(group.rows.map { it.orders.map(&:id) }).to eq([ [ order.id ], [ order.id ] ])
      expect(group.total).to eq(200)
      expect(group.meals).to eq(2)
      expect(summary.history).to be_empty
      expect(select_queries { Provider::CollectionGroupSerializer.new(group).to_h }).to be_empty
    end
  end

  it "keeps settled history metadata without loading or serializing its individual orders" do
    order = create_order(menu:, date: Date.current.prev_month.beginning_of_month + 8)
    order.accounts.each do |account|
      account.payments.create!(
        provider:, status: :approved,
        receipt: Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png")
      )
    end
    company = order.accounts.find(&:company?)
    invoice = company.invoices.create!(
      issued_on: Date.current, total_amount: company.amount,
      file: Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png")
    )

    summary = described_class.new(provider:)
    group = summary.history.sole
    expect(summary.pending).to be_empty
    expect(group.rows).to all(satisfy { !it.account.association(:orders).loaded? })
    serialized = nil
    expect(select_queries { serialized = Provider::CollectionGroupSerializer.new(group).to_h }).to be_empty

    expect(serialized).to include("total" => 200.0, "confirmed_total" => 200.0, "meals" => 2)
    expect(serialized["company"]["invoice"]).to include("id" => invoice.id, "total_amount" => 100.0)
    [ serialized["company"], *serialized["employees"] ].each do |row|
      expect(row).to include("orders" => [], "amount" => 100.0, "status" => "approved", "meals" => 2)
      expect(row["paid_on"]).to eq(Date.current.strftime("%d/%m/%y"))
      expect(row["payments"].sole).to include("status" => "approved", "receipt_content_type" => "image/png")
      expect(row["payments"].sole["receipt_url"]).to be_present
    end

    individual_row = described_class.row_for(company.reload)
    expect(individual_row.orders.map(&:id)).to eq([ order.id ])
    expect(Provider::CollectionAccountSerializer.new(individual_row).to_h["orders"].pluck("id")).to eq([ order.id ])
  end

  it "loads only confirmed orders for pending accounts and excludes other providers" do
    confirmed = create_order(menu:, date: Date.current.beginning_of_month + 8)
    %i[pending cancelled rejected].each_with_index do |status, index|
      create_order(menu:, date: Date.current.beginning_of_month + 9 + index, status:)
    end
    other_menu = providers(:endulzate).menus.create!(name: "Otro plato", description: "Con guarnición", price: 100)
    create_order(menu: other_menu, date: Date.current.beginning_of_month + 8)

    group = described_class.new(provider:).pending.sole
    expect(group.rows).to all(satisfy { it.account.provider_id == provider.id })
    group.rows.each do |row|
      expect(row.account.association(:orders)).to be_loaded
      expect(row.account.orders.map(&:id)).to eq([ confirmed.id ])
      expect(row.orders.map(&:id)).to eq([ confirmed.id ])
    end
  end

  it "keeps index queries constant as pending orders with different schedules increase" do
    2.times { |day| create_order(menu:, date: Date.current.beginning_of_month + day) }
    small_queries = select_queries { serialize_summary(described_class.new(provider:)) }
    (2...12).each { |day| create_order(menu:, date: Date.current.beginning_of_month + day) }
    large_queries = select_queries { serialize_summary(described_class.new(provider:)) }

    expect(large_queries.size).to eq(small_queries.size)
  end

  it "keeps individual order payloads empty and queries constant as settled historical orders increase" do
    month = Date.current.prev_month.beginning_of_month
    2.times { |day| create_order(menu:, date: month + day) }
    provider.accounts.each { it.payments.create!(provider:, status: :approved) }
    small_response = nil
    small_queries = select_queries { small_response = serialize_summary(described_class.new(provider:)) }

    (2...12).each { |day| create_order(menu:, date: month + day) }
    large_response = nil
    large_queries = select_queries { large_response = serialize_summary(described_class.new(provider:)) }

    expect(large_queries.size).to eq(small_queries.size)
    expect(large_response["history"].sole["company"]["orders"]).to eq([])
    small_rows = [ small_response["history"].sole["company"], *small_response["history"].sole["employees"] ]
    large_rows = [ large_response["history"].sole["company"], *large_response["history"].sole["employees"] ]
    expect(large_rows.map { it["orders"] }).to eq(small_rows.map { it["orders"] })
    expect(large_response["history"].sole).to include("total" => 2400.0, "meals" => 24)
  end

  it "keeps the sales detail query count constant as orders with different schedules increase" do
    2.times { |day| create_order(menu:, date: Date.current.beginning_of_month + day) }
    small_queries = select_queries { described_class.new(provider:).sales_detail }

    (2...12).each { |day| create_order(menu:, date: Date.current.beginning_of_month + day) }
    large_queries = select_queries { described_class.new(provider:).sales_detail }

    expect(large_queries.size).to eq(small_queries.size)
  end

  it "preserves sales amounts and delivery grouping while excluding other providers, months and unconfirmed orders" do
    dates = [ Date.current.beginning_of_month + 8, Date.current.beginning_of_month + 9 ]
    orders = dates.map { |date| create_order(menu:, date:) }
    create_order(menu:, date: Date.current.prev_month.beginning_of_month)
    create_order(menu:, date: Date.current.beginning_of_month + 10, status: :pending)
    other_menu = providers(:endulzate).menus.create!(name: "Otro plato", description: "Con guarnición", price: 100)
    create_order(menu: other_menu, date: Date.current.beginning_of_month)

    summary = described_class.new(provider:)
    detail = summary.sales_detail
    detail_orders = detail[:days].flat_map { it[:orders] }

    expect(detail[:month]).to eq(I18n.l(Date.current.beginning_of_month, format: :month_name_year))
    expect(detail[:clients]).to eq([ { id: consumer.company.id, name: consumer.company.name } ])
    expect(detail[:days].pluck(:date)).to eq(dates.reverse.map { it.strftime("%d/%m") })
    expect(detail[:days].map { it[:orders].pluck(:id) }).to eq(orders.reverse.map { [ it.id ] })
    expect(detail_orders.sum { it[:amount] }).to eq(400.0)
    expect(detail_orders.sum { it[:meals] }).to eq(4)
    expect(summary.sales).to eq(total: 400.0, meals: 4)
  end
end
