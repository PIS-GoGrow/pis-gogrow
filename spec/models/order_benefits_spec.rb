# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderBenefit, type: :model do
  fixtures :benefits, :orders, :consumers, :schedules, :menus, :providers, :companies, :users, :benefit_configurations

  describe "associations and validations" do
    let(:order_benefit) do
      OrderBenefit.create!(
        benefit: benefits(:monthly),
        order: orders(:upcoming_pending_future),
        benefit_used: 1
      )
    end

    it "belongs to a benefit" do
      expect(order_benefit.benefit).to eq(benefits(:monthly))
    end

    it "belongs to an order" do
      expect(order_benefit.order).to eq(orders(:upcoming_pending_future))
    end

    it "persists benefit_used correctly" do
      expect(order_benefit.benefit_used).to eq(1)
    end

    it "requires benefit and order" do
      expect(OrderBenefit.new(benefit_used: 1)).not_to be_valid
      expect(OrderBenefit.new(benefit: benefits(:monthly), benefit_used: 1)).not_to be_valid
      expect(OrderBenefit.new(order: orders(:upcoming_pending_future), benefit_used: 1)).not_to be_valid
    end
  end
end
