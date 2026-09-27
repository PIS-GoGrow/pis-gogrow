# frozen_string_literal: true

class BenefitRuleSerializer < ApplicationSerializer
  typelize_from BenefitRule

  attributes :id, :type, :limit, :max_price, :deadline_date, :deadline_days, :effective_from, :min_years, :created_at
end