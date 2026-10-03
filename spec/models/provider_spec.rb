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
end

# == Schema Information
#
# Table name: providers
#
#  id             :bigint           not null, primary key
#  home_delivery  :boolean          default(TRUE), not null
#  order_deadline :time
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :bigint
#
# Indexes
#
#  index_providers_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
