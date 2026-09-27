# frozen_string_literal: true

class BenefitConfiguration < ApplicationRecord
  belongs_to :company
  belongs_to :created_by, class_name: "User"

  validates :subsidy_percentage, presence: true,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :monthly_voucher_limit, presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :max_voucher_price, presence: true,
    numericality: { greater_than: 0 }
  validates :effective_from, presence: true,
    comparison: { greater_than_or_equal_to: -> { Date.current } }
  validates :effective_from, uniqueness: { scope: :company_id }

  scope :ordered, -> { order(effective_from: :desc, created_at: :desc) }

  def self.current_for(company)
    where(company: company).where(effective_from: ..Date.current).ordered.first
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
