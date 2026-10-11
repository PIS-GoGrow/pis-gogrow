# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider collection details", type: :request do
  fixtures :users, :companies, :consumers, :providers

  let(:provider) { providers(:office_provider) }
  let(:consumer) { consumers(:one) }
  let(:month) { Date.current.prev_month.beginning_of_month }

  def create_order(index, status: :confirmed)
    menu = provider.menus.create!(name: "Plato #{index}", description: "Con guarnición", price: 100)
    schedule = menu.schedules.create!(date: month + (index * 7 % 28), amount: 20)
    Order.create!(
      consumer:, schedule:, status:, amount: 2, price: 200 + index, discounted_price: 100 + index,
      delivery_method: :office, created_at: month.in_time_zone + index.seconds
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

  def previous_payload(account)
    account = provider.accounts.preload(:payments, :owner).find(account.id)
    Provider::CollectionsShowSerializer.new({
      account: ProviderCollectionSummary.row_for(account),
      orders: account.orders.confirmed.preload(consumer: :user, schedule: :menu).order(:created_at),
      payments: account.payments.order(created_at: :desc)
    }).to_h.deep_symbolize_keys
  end

  [ :consumer, :company ].each do |source|
    [ :pending, :approved ].each do |status|
      it "preserves the #{source} #{status} JSON and keeps queries constant as orders increase" do
        orders = [ create_order(0), create_order(1) ]
        create_order(2, status: :pending)
        account = orders.first.accounts.find { it.company? == (source == :company) }
        if status == :approved
          account.payments.create!(
            provider:, status: :approved,
            receipt: Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png")
          )
        end
        if source == :company
          account.invoices.create!(
            issued_on: Date.current, total_amount: account.reload.amount,
            file: Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png")
          )
        end
        expected = previous_payload(account)
        sign_in provider.user, role: :provider
        get provider_collection_path(account)
        small_queries = select_queries { get provider_collection_path(account) }

        expect(inertia).to render_component("provider/collections/show")
        expect(inertia).to have_props { |page|
          expect(page.slice(:account, :orders, :payments).deep_symbolize_keys).to eq(expected)
          expect(page[:orders].pluck(:id)).to eq(orders.map(&:id))
          expect(page[:account][:orders].pluck(:id)).to eq(orders.reverse.map(&:id))
          expect(page[:account][:status]).to eq(status.to_s)
          true
        }

        (3...13).each { |index| create_order(index) }
        expected = previous_payload(account)
        large_queries = select_queries { get provider_collection_path(account) }

        expect(large_queries.size).to eq(small_queries.size)
        expect(inertia).to have_props { |page|
          page.slice(:account, :orders, :payments).deep_symbolize_keys == expected && page[:orders].size == 12
        }

        sign_in providers(:endulzate).user, role: :provider
        get provider_collection_path(account)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  it "preserves an empty account's payload" do
    account = provider.accounts.create!(owner: consumer, month:, amount: 0)
    expected = previous_payload(account)
    sign_in provider.user, role: :provider

    get provider_collection_path(account)

    expect(inertia).to have_props { |page|
      page.slice(:account, :orders, :payments).deep_symbolize_keys == expected && page[:orders].empty?
    }
  end
end
