# frozen_string_literal: true

class Consumer < ApplicationRecord
  include SyncsUserRoles

  belongs_to :company
  belongs_to :user

  has_many :orders, dependent: :destroy
  has_many :benefits
  has_many :accounts, as: :owner
  has_many :user_notifications, as: :user
  has_many :notification_configurations, through: :user_notifications, source: :notification_configuration

  def total_debt
    accounts.pending.sum :amount
  end

  def current_month_spending
    accounts.current.sum :amount
  end

  def current_benefit
    benefits.current.monthly.first
  end

  def benefit_available
    current_benefit&.amount || 0
  end

  def subsidized_meals_used_this_month
    orders
      .joins(:schedule)
      .where(schedules: { date: Date.current.all_month })
      .where(status: [ :confirmed ])
      .sum(:amount)
  end

  def subsidized_meals_used_this_week
    orders
      .joins(:schedule)
      .where(schedules: { date: Date.current.all_week })
      .where(status: :confirmed)
      .sum(:amount)
  end

  def remaining_subsidized_meals
    [ benefit_available - subsidized_meals_used_this_month, 0 ].max
  end

  # Se espera que no se incluyan direcciones blank acá
  def delivery_addresses
    [ address, company.address ].compact_blank
  end

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
