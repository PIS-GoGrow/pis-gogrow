# frozen_string_literal: true

class Consumer < ApplicationRecord
  include SyncsUserRoles

  SUBSIDIZED_MEALS_LIMIT = 20

  belongs_to :company
  belongs_to :user

  has_many :orders, dependent: :destroy
  has_many :benefits
  has_many :accounts, as: :owner
  has_many :user_notifications, as: :user
  has_many :notification_configurations, through: :user_notifications, source: :notification_configuration

  has_many :consumer_benefit_configurations
  has_many :benefit_configurations, through: :consumer_benefit_configurations

  # La modalidad se deriva de la dirección elegida: la de la oficina es entrega en
  # oficina y cualquier otra es domicilio. Un proveedor que no entrega a domicilio
  # fuerza oficina, y el carrito se lo avisa al empleado.
  def delivery_for(provider, chosen_address)
    if provider.home_delivery? && chosen_address.present? && chosen_address != company.address
      { delivery_method: "home", address: chosen_address }
    else
      { delivery_method: "office", address: company.address }
    end
  end

  def total_debt
    accounts.pending.sum :amount
  end

  def current_month_spending
    accounts.current.sum :amount
  end

  def current_monthly_benefit
    benefits.current.monthly.first
  end

  def benefit_available
    current_monthly_benefit&.amount || 0
  end

  # Devuelve las órdenes del cliente en las que se usó un beneficio mensual
  def subsidized_orders
    orders.joins(benefits: { benefit_configuration: :benefit_rules })
          .where(benefit_rules: { type: MonthlyBenefit.name })
  end

  # Devuelve la cantidad de viandas compradas en órdenes confirmadas este mes, para
  # las que se usó un beneficio mensual
  def subsidized_meals_used_this_month
    orders
      .joins(:schedule)
      .where(schedules: { date: Date.current.all_month })
      .where.not(status: [:rejected, :cancelled])
      .where(id: subsidized_orders)
      .sum(:amount)
  end

  # Devuelve la cantidad de viandas compradas en órdenes confirmadas esta semana
  def subsidized_meals_used_this_week
    orders
      .joins(:schedule)
      .where(schedules: { date: Date.current.all_week })
      .where.not(status: [:rejected, :cancelled])
      .where(id: subsidized_orders)
      .sum(:amount)
  end

  def remaining_subsidized_meals
    [ benefit_available - subsidized_meals_used_this_month, 0 ].max
  end

  def remaining_subsidized_meals
    [ SUBSIDIZED_MEALS_LIMIT - subsidized_meals_used_this_month, 0 ].max
  end

  # TODO: Cómo obtenemos el cumpleaños del empleado?
  def birthday
    Date.current - 1.day
  end

  # TODO: Cómo obtenemos el onboarding del empleado?
  def onboarding_date
    Date.current - 1.day
  end
end

# == Schema Information
#
# Table name: consumers
#
#  id         :bigint           not null, primary key
#  address    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_consumers_on_company_id  (company_id)
#  index_consumers_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (user_id => users.id)
#
