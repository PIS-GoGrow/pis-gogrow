# frozen_string_literal: true

class BenefitConfigurationSerializer < ApplicationSerializer
  typelize_from BenefitConfiguration

  attributes :id, :subsidy_percentage, :monthly_voucher_limit, :max_voucher_price, :effective_from, :created_at

  typelize :string
  attribute :created_by_name do |benefit_configuration|
    benefit_configuration.created_by.name
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
