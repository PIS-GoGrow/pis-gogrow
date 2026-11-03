# frozen_string_literal: true

class Admin::BenefitUsageAnalysisSerializer < ApplicationSerializer
  typelize month: :string, current_month: :string
  attributes :month, :current_month

  typelize months: "Array<{ key: string; label: string }>"
  attributes :months
end
