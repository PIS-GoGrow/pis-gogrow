# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitRule, type: :model do
  fixtures :benefit_configurations, :benefit_rules, :companies, :users, :consumers

  let(:configuration) { benefit_configurations(:gift) }
  let(:consumer) { consumers(:one) }

  describe "associations" do
    it "belongs to a benefit_configuration" do
      rule = benefit_rules(:gift)
      expect(rule.benefit_configuration).to be_present
    end
  end

  describe "interface methods" do
    let(:base_rule) { BenefitRule.new(benefit_configuration: configuration) }

    it "raises NotImplementedError on applicable_to?" do
      expect { base_rule.applicable_to?(consumer) }.to raise_error(NotImplementedError, /debe implementar applicable_to\?/)
    end

    it "raises NotImplementedError on benefit_limit" do
      expect { base_rule.benefit_limit }.to raise_error(NotImplementedError, /debe implementar benefit_limit/)
    end

    it "raises NotImplementedError on benefit_deadline" do
      expect { base_rule.benefit_deadline(consumer) }.to raise_error(NotImplementedError, /debe implementar benefit_deadline/)
    end
  end

  describe "validations: monthly_benefit_exclusivity" do
    let(:monthly_config) { benefit_configurations(:monthly) }

    it "does not allow adding another rule to a configuration that already has a MonthlyBenefit" do
      additional_rule = monthly_config.benefit_rules.build(type: "GiftBenefit", limit: 5)
      expect(additional_rule).not_to be_valid
      expect(additional_rule.errors[:base]).to include("No se puede agregar otra regla cuando ya existe MonthlyBenefit")
    end

    it "does not allow adding a MonthlyBenefit to a configuration that already has other rules" do
      gift_config = benefit_configurations(:gift)
      monthly_rule = gift_config.benefit_rules.build(type: "MonthlyBenefit", limit: 10, max_price: 300)
      expect(monthly_rule).not_to be_valid
      expect(monthly_rule.errors[:base]).to include("MonthlyBenefit no puede coexistir con otras benefit_rules")
    end

    it "allows multiple non-monthly rules in the same configuration" do
      seniority_config = benefit_configurations(:seniority)
      gift_rule = seniority_config.benefit_rules.build(type: "GiftBenefit", limit: 5, effective_from: Date.current, deadline_date: Date.current + 10.days)
      expect(gift_rule).to be_valid
    end
  end
end

# == Schema Information
#
# Table name: benefit_rules
#
#  id                       :bigint           not null, primary key
#  deadline_date            :date
#  deadline_days            :integer
#  effective_from           :date
#  limit                    :integer
#  max_price                :decimal(10, 2)
#  min_years                :integer
#  type                     :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  benefit_configuration_id :bigint           not null
#
# Indexes
#
#  index_benefit_rules_on_benefit_configuration_id  (benefit_configuration_id)
#
# Foreign Keys
#
#  fk_rails_...  (benefit_configuration_id => benefit_configurations.id)
#
