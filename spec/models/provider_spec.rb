# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider, type: :model do
  fixtures :providers

  describe "#delivery_methods" do
    it "lists only office for an office-only provider" do
      expect(providers(:office_provider).delivery_methods).to eq([ "office" ])
    end

    it "lists every method when home delivery is on" do
      expect(providers(:tuviandita).delivery_methods).to eq(Order.delivery_methods.keys)
    end
  end

  describe "#home_delivery" do
    it "defaults to true for a new provider" do
      expect(described_class.new.home_delivery).to be true
    end

    it "persists false when disabling home delivery" do
      provider = providers(:tuviandita)
      provider.update!(home_delivery: false)

      expect(provider.reload.home_delivery).to be false
      expect(provider.delivery_methods).to eq([ "office" ])
    end

    it "raises NotNullViolation when home_delivery is set to nil (database integrity)" do
      provider = providers(:tuviandita)

      expect {
        provider.update_column(:home_delivery, nil)
      }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end

  describe "#allows_delivery_method?" do
    it "is false for a method outside the provider policy" do
      expect(providers(:office_provider).allows_delivery_method?(:home)).to be false
      expect(providers(:office_provider).allows_delivery_method?("office")).to be true
    end

    it "is true for every method when home delivery is on" do
      expect(providers(:tuviandita).allows_delivery_method?(:office)).to be true
      expect(providers(:tuviandita).allows_delivery_method?(:home)).to be true
    end
  end

  describe "#order_deadline_passed_today?" do
    let(:provider) { providers(:tuviandita) }

    around do |example|
      travel_to(Time.zone.local(2026, 10, 2, 11, 30)) { example.run }
    end

    it "is false without a deadline" do
      provider.order_deadline = nil

      expect(provider.order_deadline_passed_today?).to be false
    end

    it "is false a minute before the deadline" do
      provider.order_deadline = Time.zone.parse("11:31")

      expect(provider.order_deadline_passed_today?).to be false
    end

    it "is true right at the deadline" do
      provider.order_deadline = Time.zone.parse("11:30")

      expect(provider.order_deadline_passed_today?).to be true
    end

    it "is true once the deadline has passed" do
      provider.order_deadline = Time.zone.parse("11:29")

      expect(provider.order_deadline_passed_today?).to be true
    end
  end

  describe "#closed_on?" do
    let(:provider) { providers(:tuviandita) }
    let(:monday) { Date.new(2026, 10, 12) }

    around do |example|
      travel_to(Time.zone.local(2026, 10, 12, 9, 0)) { example.run }
    end

    it "is false without closures" do
      expect(provider.closed_on?(monday)).to be false
    end

    it "is true on every day of a closure, ends included" do
      provider.closures.create!(starts_on: monday + 1, ends_on: monday + 3, reason: "Vacaciones")

      expect((monday + 1..monday + 3).map { provider.closed_on?(it) }).to all(be true)
    end

    it "is false the day before and the day after" do
      provider.closures.create!(starts_on: monday + 1, ends_on: monday + 3, reason: "Vacaciones")

      expect(provider.closed_on?(monday)).to be false
      expect(provider.closed_on?(monday + 4)).to be false
    end

    it "only looks at its own closures" do
      providers(:endulzate).closures.create!(starts_on: monday + 1, ends_on: monday + 3, reason: "Vacaciones")

      expect(provider.closed_on?(monday + 2)).to be false
    end

    it "does not run a query per date once the closures are loaded" do
      provider.closures.create!(starts_on: monday + 1, ends_on: monday + 1, reason: "Feriado")
      loaded = described_class.includes(:closures).find(provider.id)

      queries = []
      callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        5.times { |day| loaded.closed_on?(monday + day) }
      end

      expect(queries).to be_empty
    end
  end
end

# == Schema Information
#
# Table name: providers
#
#  id                  :bigint           not null, primary key
#  bank_account_holder :string
#  bank_account_number :string
#  bank_account_type   :integer
#  bank_name           :string
#  home_delivery       :boolean          default(TRUE), not null
#  order_deadline      :time
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  tax_id              :string
#  user_id             :bigint
#
# Indexes
#
#  index_providers_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
