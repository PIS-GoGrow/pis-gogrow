# frozen_string_literal: true

class SpecialSubsidySerializer < ApplicationSerializer
  typelize_from BenefitConfiguration

  attributes :id, :name, :subsidy_percentage, :applies_to_all

  typelize "number[]"
  attribute :consumer_ids do |benefit_configuration|
    benefit_configuration.consumers.map(&:id)
  end

  typelize "{ type: 'seniority' | 'birthday' | 'onboarding' | 'gift'; min_years?: number | null; limit?: number | null; validity_amount?: number | null; validity_unit?: 'days' | 'weeks' | 'months'; effective_from?: string | null } | null"
  attribute :condition, &:special_condition
end
