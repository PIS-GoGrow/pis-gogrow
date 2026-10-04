# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitConfiguration, type: :model do
  fixtures :users, :companies, :benefit_configurations, :consumers

  let(:company) { companies(:gogrow) }
  let(:admin_user) { users(:admin) }

  def build_base_subsidy(**attrs)
    BenefitConfiguration.new_base_subsidy(
      **{
        company: company,
        created_by: admin_user,
        subsidy_percentage: 50,
        limit: 20,
        max_price: 300,
        effective_from: Date.current
      }.merge(attrs)
    )
  end

  def build_configuration(**attrs)
    BenefitConfiguration.new(
      {
        company: company,
        created_by: admin_user,
        subsidy_percentage: 50
      }.merge(attrs)
    )
  end

  describe "#new_base_subsidy" do
    it "is valid with the reference values" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy).to be_valid
    end

    it "rejects a negative subsidy percentage" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(subsidy_percentage: -1)).not_to be_valid
    end

    it "rejects a subsidy percentage over 100" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(subsidy_percentage: 101)).not_to be_valid
    end

    it "rejects a negative monthly voucher limit" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(limit: -1)).not_to be_valid
    end

    it "rejects a max_voucher_price of zero" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(max_price: 0)).not_to be_valid
    end

    it "rejects a negative max_voucher_price" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(max_price: -1)).not_to be_valid
    end

    it "rejects a missing max_voucher_price" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(max_price: nil)).not_to be_valid
    end

    it "rejects an effective_from date in the past" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(effective_from: 1.day.ago.to_date)).not_to be_valid
    end

    it "accepts today as effective_from" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(effective_from: Date.current)).to be_valid
    end

    it "rejects a duplicate effective_from for the same company" do
      expect(build_base_subsidy(subsidy_percentage: 60)).not_to be_valid
    end

    it "allows the same effective_from for a different company" do
      other_company = Company.create!(name: "Other Co", address: "Somewhere 123")

      expect(build_base_subsidy(company: other_company)).to be_valid
    end

    it "accepts 0% subsidy percentage" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(subsidy_percentage: 0)).to be_valid
    end

    it "accepts 100% subsidy percentage" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(subsidy_percentage: 100)).to be_valid
    end

    it "rejects a missing subsidy percentage" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(subsidy_percentage: nil)).not_to be_valid
    end

    it "rejects a non-integer monthly voucher limit" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(limit: 10.5)).not_to be_valid
    end

    it "rejects a missing monthly voucher limit" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(limit: nil)).not_to be_valid
    end

    it "accepts a positive decimal max_voucher_price" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(max_price: 150.75)).to be_valid
    end

    it "accepts the minimum positive max_voucher_price" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(max_price: 0.01)).to be_valid
    end

    it "rejects a missing company" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(company: nil)).not_to be_valid
    end

    it "rejects a missing created_by user" do
      benefit_configurations(:monthly).destroy

      expect(build_base_subsidy(created_by: nil)).not_to be_valid
    end
  end

  describe "#monthly_ordered" do
    it "orders by effective_from desc" do
      older = build_base_subsidy(effective_from: 1.month.from_now.to_date, subsidy_percentage: 60)
      older.save!

      expect(BenefitConfiguration.monthly_ordered.to_a).to eq([ older, benefit_configurations(:monthly) ])
    end
  end

  describe "#base_subsidy_for" do
    it "returns nil when the company has no configuration yet" do
      benefit_configurations(:monthly).destroy

      expect(BenefitConfiguration.base_subsidy_for(company)).to be_nil
    end

    it "ignores configurations that are not effective yet" do
      benefit_configurations(:monthly).destroy

      current = build_base_subsidy(effective_from: Date.current)
      current.save!
      build_base_subsidy(effective_from: 1.month.from_now.to_date, subsidy_percentage: 70).save!

      expect(BenefitConfiguration.base_subsidy_for(company)).to eq(current)
    end

    it "returns the most recent configuration among multiple past ones" do
      older = build_configuration(subsidy_percentage: 30)
      older.save!(validate: false)
      older.new_monthly_benefit(effective_from: 2.month.ago.to_date, limit: 20, max_price: 500)
           .save!(validate: false)

      recent = build_configuration(subsidy_percentage: 50)
      recent.save!(validate: false)
      recent.new_monthly_benefit(effective_from: 1.month.ago.to_date, limit: 20, max_price: 500)
            .save!(validate: false)

      expect(BenefitConfiguration.base_subsidy_for(company)).to eq(benefit_configurations(:monthly))
    end

    it "does not return configurations from another company" do
      other_company = Company.create!(name: "Other Co", address: "Somewhere 123")

      expect(BenefitConfiguration.base_subsidy_for(other_company)).to be_nil
    end

    it "picks up a new configuration once its effective_from date arrives, without altering the previous one" do
      benefit_configurations(:monthly).destroy

      original = build_base_subsidy(effective_from: Date.current)
      original.save!

      travel_to(1.day.from_now) do
        upcoming = build_base_subsidy(effective_from: Date.current, subsidy_percentage: 60)
        upcoming.save!

        expect(BenefitConfiguration.base_subsidy_for(company)).to eq(upcoming)
      end

      expect(original.reload.subsidy_percentage).to eq(50)
    end
  end

  describe "apply_to_all_consumers" do
    before do
      BenefitConfiguration.destroy_all
      Benefit.destroy_all
    end

    it "applies monthly benefits to associated consumers" do
      benefit_configuration = build_base_subsidy
      benefit_configuration.save
      benefit_configuration.consumers = [ consumers(:one) ]

      expect(consumers(:one).reload.benefits.count).to eq(0)
      benefit_configuration.apply_to_all_consumers
      expect(consumers(:one).benefits.count).to eq(1)
      expect(consumers(:one).benefits.first.percentage).to eq(50)
      expect(consumers(:one).benefits.first.amount).to eq(20)
      expect(consumers(:one).benefits.first.due_date).to eq(Date.current.end_of_month)
    end

    it "does not apply monthly benefits to not associated consumers" do
      benefit_configuration = build_base_subsidy
      benefit_configuration.save
      benefit_configuration.consumers = [ consumers(:one) ]

      expect(consumers(:other).reload.benefits.count).to eq(0)
      benefit_configuration.apply_to_all_consumers
      expect(consumers(:other).benefits.count).to eq(0)
    end

    it "applies gift benefits to associated consumers" do
      benefit_configuration = build_configuration
      benefit_configuration.benefit_rules.new(
        type: GiftBenefit.name,
        limit: 10,
        effective_from: Date.current,
        deadline_date: Date.current + 1
      )
      benefit_configuration.save
      benefit_configuration.consumers = [ consumers(:one) ]

      expect(consumers(:one).reload.benefits.count).to eq(0)
      benefit_configuration.apply_to_all_consumers
      expect(consumers(:one).benefits.count).to eq(1)
      expect(consumers(:one).benefits.first.percentage).to eq(50)
      expect(consumers(:one).benefits.first.amount).to eq(10)
      expect(consumers(:one).benefits.first.due_date).to eq(Date.current + 1)
    end

    it "does not apply gift benefits to associated consumers when out of date" do
      benefit_configuration = build_configuration
      benefit_configuration.benefit_rules.new(
        type: GiftBenefit.name,
        limit: 10,
        effective_from: Date.current + 1,
        deadline_date: Date.current + 1
      )
      benefit_configuration.save
      benefit_configuration.consumers = [ consumers(:one) ]

      benefit_configuration.apply_to_all_consumers
      expect(consumers(:one).benefits.count).to eq(0)

      benefit_configuration = build_configuration
      benefit_configuration.benefit_rules.new(
        type: GiftBenefit.name,
        limit: 10,
        effective_from: Date.current - 1,
        deadline_date: Date.current - 1
      )
      benefit_configuration.save
      benefit_configuration.consumers = [ consumers(:one) ]

      benefit_configuration.apply_to_all_consumers
      expect(consumers(:one).benefits.count).to eq(0)
    end
  end
end

# == Schema Information
#
# Table name: benefit_configurations
#
#  id                 :bigint           not null, primary key
#  applies_to_all     :boolean          default(FALSE)
#  deactivated_at     :datetime
#  name               :string
#  subsidy_percentage :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  company_id         :bigint           not null
#  created_by_id      :bigint           not null
#
# Indexes
#
#  index_benefit_configurations_on_company_id     (company_id)
#  index_benefit_configurations_on_created_by_id  (created_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#
