# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderBenefit, type: :model do
  fixtures :benefits, :orders, :schedules, :menus, :providers, :consumers, :users, :companies, :benefit_configurations

  let(:order) { orders(:upcoming_pending_today) }
  let(:benefit) { benefits(:monthly) }

  describe "validations" do
    it "is valid when benefit has no due_date" do
      benefit.update_column(:due_date, nil)
      order_benefit = described_class.new(order:, benefit:, benefit_used: 1)

      expect(order_benefit).to be_valid
    end

    it "is valid when delivery date is on or before due_date" do
      benefit.update_column(:due_date, order.schedule.date + 1.day)
      order_benefit = described_class.new(order:, benefit:, benefit_used: 1)

      expect(order_benefit).to be_valid
    end

    it "is invalid when delivery date is after due_date" do
      benefit.update_column(:due_date, order.schedule.date - 1.day)
      order_benefit = described_class.new(order:, benefit:, benefit_used: 1)

      expect(order_benefit).not_to be_valid
      expect(order_benefit.errors[:benefit]).to include("está vencido para la fecha del pedido")
    end
  end

  describe "associations" do
    it "belongs to an order" do
      order_benefit = described_class.new(order:, benefit:, benefit_used: 1)
      expect(order_benefit.order).to eq(order)
    end

    it "belongs to a benefit" do
      order_benefit = described_class.new(order:, benefit:, benefit_used: 1)
      expect(order_benefit.benefit).to eq(benefit)
    end
  end
end

# == Schema Information
#
# Table name: order_benefits
#
#  id           :bigint           not null, primary key
#  benefit_used :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  benefit_id   :bigint           not null
#  order_id     :bigint           not null
#
# Indexes
#
#  index_order_benefits_on_benefit_id  (benefit_id)
#  index_order_benefits_on_order_id    (order_id)
#
# Foreign Keys
#
#  fk_rails_...  (benefit_id => benefits.id)
#  fk_rails_...  (order_id => orders.id)
#
