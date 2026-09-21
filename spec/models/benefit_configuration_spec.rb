# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitConfiguration, type: :model do
  fixtures :users, :companies

  let(:company) { companies(:gogrow) }
  let(:admin_user) { users(:admin) }

  def build_configuration(**attrs)
    BenefitConfiguration.new(
      {
        company: company,
        created_by: admin_user,
        subsidy_percentage: 50,
        max_voucher_price: 150,
        monthly_voucher_limit: 20,
        effective_from: Date.current
      }.merge(attrs)
    )
  end

  it "is valid with the reference values" do
    expect(build_configuration).to be_valid
  end

  it "rejects a negative subsidy percentage" do
    expect(build_configuration(subsidy_percentage: -1)).not_to be_valid
  end

  it "rejects a subsidy percentage over 100" do
    expect(build_configuration(subsidy_percentage: 101)).not_to be_valid
  end

  it "rejects a negative monthly voucher limit" do
    expect(build_configuration(monthly_voucher_limit: -1)).not_to be_valid
  end

  it "rejects a max_voucher_price of zero" do
    expect(build_configuration(max_voucher_price: 0)).not_to be_valid
  end

  it "rejects a negative max_voucher_price" do
    expect(build_configuration(max_voucher_price: -1)).not_to be_valid
  end

  it "rejects a missing max_voucher_price" do
    expect(build_configuration(max_voucher_price: nil)).not_to be_valid
  end

  it "rejects an effective_from date in the past" do
    expect(build_configuration(effective_from: 1.day.ago.to_date)).not_to be_valid
  end

  it "accepts today as effective_from" do
    expect(build_configuration(effective_from: Date.current)).to be_valid
  end

  it "rejects a duplicate effective_from for the same company" do
    build_configuration.save!

    expect(build_configuration(subsidy_percentage: 60)).not_to be_valid
  end

  it "allows the same effective_from for a different company" do
    build_configuration.save!
    other_company = Company.create!(name: "Other Co", address: "Somewhere 123")

    expect(build_configuration(company: other_company)).to be_valid
  end

  describe ".current_for" do
    it "returns nil when the company has no configuration yet" do
      expect(BenefitConfiguration.current_for(company)).to be_nil
    end

    it "ignores configurations that are not effective yet" do
      current = build_configuration(effective_from: Date.current)
      current.save!
      build_configuration(effective_from: 1.month.from_now.to_date, subsidy_percentage: 70).save!

      expect(BenefitConfiguration.current_for(company)).to eq(current)
    end

    it "picks up a new configuration once its effective_from date arrives, without altering the previous one" do
      original = build_configuration(effective_from: Date.current)
      original.save!

      travel_to(1.day.from_now) do
        upcoming = build_configuration(effective_from: Date.current, subsidy_percentage: 60)
        upcoming.save!

        expect(BenefitConfiguration.current_for(company)).to eq(upcoming)
      end

      expect(original.reload.subsidy_percentage).to eq(50)
    end
  end
end

# == Schema Information
#
# Table name: benefit_configurations
#
#  id                    :bigint           not null, primary key
#  effective_from        :date             not null
#  max_voucher_price     :decimal(10, 2)   not null
#  monthly_voucher_limit :integer          not null
#  subsidy_percentage    :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  company_id            :bigint           not null
#  created_by_id         :bigint           not null
#
# Indexes
#
#  index_benefit_configurations_on_company_id                     (company_id)
#  index_benefit_configurations_on_company_id_and_effective_from  (company_id,effective_from) UNIQUE
#  index_benefit_configurations_on_created_by_id                  (created_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#
