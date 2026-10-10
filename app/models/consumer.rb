# frozen_string_literal: true

class Consumer < ApplicationRecord
  include SyncsUserRoles

  belongs_to :company
  belongs_to :user

  has_many :orders, dependent: :destroy
  has_many :saved_addresses, class_name: "DeliveryAddress", dependent: :destroy
  has_many :benefits, dependent: :destroy
  has_many :accounts, as: :owner

  has_many :consumer_benefit_configurations
  has_many :benefit_configurations, through: :consumer_benefit_configurations

  def total_debt
    accounts.pending.sum :amount
  end

  # La alerta requiere acción, así que solo se cierra acá, cuando la deuda vuelve
  # al monto que fijó RRHH; mientras siga abierta no se crea otra en cada pedido.
  def check_debt_alert!
    debt = total_debt
    threshold = company.debt_alert_threshold

    if debt <= threshold
      Notification.close_by(event: "debt_threshold_exceeded", notifiable: self, user:)
    elsif !user.notifications.active.exists?(event: "debt_threshold_exceeded", notifiable: self)
      Notifier.call(
        event_key: :debt_threshold_exceeded,
        user:,
        notifiable: self,
        description_data: {
          debt: format_amount(debt),
          threshold: format_amount(threshold)
        }
      )
    end
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

  # Devuelve la cantidad de viandas subsidiadas mensuales restantes para este mes,
  # contando solo las órdenes confirmadas
  def remaining_monthly_benefit
    [ monthly_benefit_available - monthly_benefit_used_this_month, 0 ].max
  end

  # Devuelve el beneficio mensual que puede ser aplicado en un schedule.
  # Esto es, el current_monthly_benefit si la fecha del schedule lo permite,
  # o el siguiente si no.
  def monthly_benefit_for(schedule)
    monthly_benefits
      .where.not(status: :expired)
      .where(due_date: schedule.date..)
      .order(due_date: :asc) # Debería haber a lo sumo 2: uno current y uno future
      .first # Obtenemos el que debería ser el current
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

  # La oficina va primero y después la última dirección particular a la que se
  # pidió, que es la que el carrito muestra junto a la oficina.
  def delivery_address_options
    last_used = orders.home.order(created_at: :desc).pick(:address)
    saved = saved_addresses.order(created_at: :desc).map do |delivery_address|
      { id: "address-#{delivery_address.id}", label: delivery_address.name, address: delivery_address.full_address }
    end
    custom = [
      { id: "home", label: I18n.t("pages.orders.addresses.home"), address: },
      *saved,
      { id: "last_used", label: I18n.t("pages.orders.addresses.last_used"), address: last_used }
    ]

    [
      { id: "office", label: I18n.t("pages.orders.addresses.office"), address: company.address },
      *custom.partition { it[:address] == last_used }.flatten
    ].select { it[:address].present? }.uniq { it[:address] }
  end

  private

  def format_amount(amount)
    ActiveSupport::NumberHelper.number_to_rounded(
      amount, precision: 2, strip_insignificant_zeros: true, delimiter: ".", separator: ","
    )
  end
end

# == Schema Information
#
# Table name: consumers
#
#  id              :bigint           not null, primary key
#  address         :string
#  birthday        :date
#  onboarding_date :date
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  user_id         :bigint           not null
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
