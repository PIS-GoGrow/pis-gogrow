# frozen_string_literal: true

class Consumer < ApplicationRecord
  include SyncsUserRoles

  belongs_to :company
  belongs_to :user

  has_many :orders, dependent: :destroy
  has_many :benefits, dependent: :destroy
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

  # Devuelve todos los beneficios mensuales del cliente
  def monthly_benefits
    benefits.joins(benefit_configuration: :benefit_rules)
            .where(benefit_rules: { type: MonthlyBenefit.name })
  end

  def current_monthly_benefit
    benefits.current.monthly.first
  end

  def monthly_benefit_available
    current_monthly_benefit&.amount || 0
  end

  # Devuelve la cantidad de beneficios mensuales usados en total en un determinado
  # rango de fechas y especificando si contar órdenes pendientes.
  # Si se hizo una orden pidiendo dos viandas con un beneficio, esa orden cuenta
  # por dos.
  def monthly_benefit_used_in(date_range, count_pending: false)
    valid_status = [ :rejected, :cancelled ]
    valid_status << :pending if count_pending

    OrderBenefit
      .joins(order: :schedule)
      .where(schedules: { date: date_range })
      .where.not(orders: { status:  valid_status })
      .where(benefit_id: monthly_benefits)
      .sum(:benefit_used)
  end

  # Devuelve la cantidad de viandas compradas en órdenes confirmadas este mes, para
  # las que se usó un beneficio mensual
  def monthly_benefit_used_this_month
    monthly_benefit_used_in Date.current.all_month
  end

  # Devuelve la cantidad de viandas compradas en órdenes confirmadas esta semana
  def monthly_benefit_used_this_week
    monthly_benefit_used_in Date.current.all_week
  end

  def remaining_monthly_benefit
    [ monthly_benefit_available - monthly_benefit_used_this_month, 0 ].max
  end

  # TODO: Cómo obtenemos el cumpleaños del empleado?
  attr_accessor :bithday

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
