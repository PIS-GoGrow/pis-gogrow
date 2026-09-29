# frozen_string_literal: true

# Representa un beneficio que posee actualmente el consumidor.
# Se puede pensar como un cupón, con una límite de uso (de tiempo y de cantidad)
# y con un porcentaje de subsidio. Guarda además referencia a qué órdenes lo usaron
# y qué configuración lo generó.
class Benefit < ApplicationRecord
  belongs_to :consumer
  has_many :order_benefits, dependent: :destroy
  has_many :orders, through: :order_benefits, source: :order
  belongs_to :benefit_configuration

  validates :percentage, presence: true,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validate :only_one_monthly_benefit_per_consumer, if: :monthly?

  # Es importante que current sea 0
  enum :status, { current: 0, expired: 1 }, default: :current

  scope :monthly, -> {
    joins(benefit_configuration: :benefit_rules)
      .where(
        benefit_configuration: {
          benefit_rules: { type: MonthlyBenefit.name }
        }
      )
      .distinct
  }

  def self.expire_old!(date)
    current
      .where(due_date: ...date)
      .update_all(status: :expired, updated_at: Time.current)
  end

  def monthly?
    benefit_configuration&.benefit_rules&.any? { |rule| rule.type == MonthlyBenefit.name }
  end

  private

  def only_one_monthly_benefit_per_consumer
    return if consumer_id.blank?

    if Benefit.monthly.current.where(consumer_id: consumer_id).where.not(id: id).exists?
      errors.add(:base, "el cliente ya tiene un beneficio mensual")
    end
  end
end

# == Schema Information
#
# Table name: benefits
#
#  id                       :bigint           not null, primary key
#  amount                   :integer
#  description              :string
#  due_date                 :date
#  percentage               :integer
#  status                   :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  benefit_configuration_id :bigint
#  consumer_id              :bigint           not null
#
# Indexes
#
#  index_benefits_on_benefit_configuration_id        (benefit_configuration_id)
#  index_benefits_on_consumer_id                     (consumer_id)
#  index_benefits_unique_active_per_consumer_config  (consumer_id,benefit_configuration_id) UNIQUE WHERE (status = 0)
#
# Foreign Keys
#
#  fk_rails_...  (benefit_configuration_id => benefit_configurations.id)
#  fk_rails_...  (consumer_id => consumers.id)
#
