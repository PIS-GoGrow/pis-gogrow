# frozen_string_literal: true

# Representa un beneficio que posee actualmente el consumidor.
# Se puede pensar como un cupón, con una límite de uso (de tiempo y de cantidad)
# y con un porcentaje de subsidio. Guarda además referencia a qué órdenes lo usaron
# y qué configuración lo generó.
class Benefit < ApplicationRecord
  belongs_to :consumer
  has_many :order_benefits
  has_many :orders, through: :order_benefits, source: :order
  belongs_to :benefit_configuration

  # Es importante que current sea 0
  enum :status, { current: 0, expired: 1 }

  scope :monthly, -> {
    joins(benefit_configuration: :benefit_rules)
      .where(
        benefit_configuration: {
          benefit_rules: { type: MonthlyBenefit.name }
        }
      )
      .distinct
  }
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
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  benefit_configuration_id :bigint           not null
#  consumer_id              :bigint           not null
#
# Indexes
#
#  index_benefits_on_benefit_configuration_id  (benefit_configuration_id)
#  index_benefits_on_consumer_id               (consumer_id)
#
# Foreign Keys
#
#  fk_rails_...  (benefit_configuration_id => benefit_configurations.id)
#  fk_rails_...  (consumer_id => consumers.id)
#
