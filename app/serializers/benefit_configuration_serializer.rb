# frozen_string_literal: true

class BenefitConfigurationSerializer < ApplicationSerializer
  typelize_from BenefitConfiguration

  attributes :id, :subsidy_percentage, :created_at

  typelize :string
  attribute :created_by_name do |benefit_configuration|
    benefit_configuration.created_by.name
  end

  typelize :number
  attribute :monthly_voucher_limit do |benefit_configuration|
    benefit_configuration.benefit_rules.first.limit
  end

  typelize :number
  attribute :max_voucher_price do |benefit_configuration|
    benefit_configuration.benefit_rules.first.max_price
  end

  typelize :string
  attribute :effective_from do |benefit_configuration|
    benefit_configuration.benefit_rules.first.effective_from
  end
end

# == Schema Information
#
# Table name: benefit_configurations
#
#  id                 :bigint           not null, primary key
#  applies_to_all     :boolean          default(FALSE)
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
