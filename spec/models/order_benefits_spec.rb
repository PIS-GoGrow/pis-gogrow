# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderBenefit, type: :model do
  fixtures :benefits, :orders, :consumers, :schedules, :menus, :providers, :companies, :users, :benefit_configurations

  describe "associations and validations" do
    let(:order_benefit) do
      OrderBenefit.create!(
        benefit: benefits(:monthly),
        order: orders(:upcoming_pending_today),
        benefit_used: 1
      )
    end

    it "belongs to a benefit" do
      expect(order_benefit.benefit).to eq(benefits(:monthly))
    end

    it "belongs to an order" do
      expect(order_benefit.order).to eq(orders(:upcoming_pending_today))
    end

    it "persists benefit_used correctly" do
      expect(order_benefit.benefit_used).to eq(1)
    end

    it "requires benefit and order" do
      expect(OrderBenefit.new(benefit_used: 1)).not_to be_valid
      expect(OrderBenefit.new(benefit: benefits(:monthly), benefit_used: 1)).not_to be_valid
      expect(OrderBenefit.new(order: orders(:upcoming_pending_today), benefit_used: 1)).not_to be_valid
    end

    it "is valid when delivery date is on or before due_date" do
      expect(order_benefit).to be_valid
    end

    it "is valid when benefit has no due_date" do
      benefits(:monthly).update_column(:due_date, nil)
      record = OrderBenefit.new(order: orders(:upcoming_pending_today), benefit: benefits(:monthly), benefit_used: 1)
      expect(record).to be_valid
    end

    it "is invalid when delivery date is after due_date" do
      record = OrderBenefit.new(order: orders(:upcoming_pending_future), benefit: benefits(:monthly), benefit_used: 1)
      expect(record).not_to be_valid
      expect(record.errors[:benefit]).to include("está vencido para la fecha del pedido")
    end
  end
end
