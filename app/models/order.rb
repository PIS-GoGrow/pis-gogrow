# frozen_string_literal: true

# Representa un pedido hecho por un consumidor a un menú. Se relaciona con la
# publicación de ese menú (su schedule) y no con el menú en sí.
# Antes crearse, debería relacionarse con un schedule y un consumer. Si es así,
# la cuenta se le asigna automáticamente. Las cuentas de una orden no deberían
# asignarse manualmente.
class Order < ApplicationRecord
  # La migración 20260911234117 usa el modelo Order, así que al reconstruir la
  # base desde cero el enum se evalúa antes de que exista su columna.
  attribute :status_before_cancellation, :integer

  enum :status, { pending: 0, confirmed: 1, cancelled: 2, rejected: 3 }, default: :pending
  enum :delivery_method, { office: 0, home: 1 }
  enum :status_before_cancellation, { pending: 0, confirmed: 1 }, prefix: :before_cancellation

  # Esta línea tiene que estar antes de has_many :order_accounts.
  # Antes de que se borre la orden, se tiene que registrar sus cuentas
  # asociadas para que estas actualicen su monto.
  before_destroy :remember_accounts

  belongs_to :consumer
  belongs_to :schedule
  belongs_to :cancelled_by, class_name: "User", optional: true
  has_one :menu, through: :schedule
  has_one :provider, through: :menu

  has_many :order_accounts, dependent: :destroy
  has_many :accounts, through: :order_accounts

  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :discounted_price, comparison: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price, comparison: { greater_than_or_equal_to: 0 }, presence: true
  validates :address, presence: true, if: :home?
  validates :delivery_method, presence: true
  validate :delivery_method_allowed_by_provider, on: :create

  # El corte entre ambas secciones es la fecha de entrega, no el estado: una
  # orden confirmada sigue necesitando seguimiento hasta que la vianda llega.
  # Cancelled y rejected son la excepción: ya no va a llegar ninguna vianda.
  scope :upcoming, -> {
    joins(:schedule)
      .where.not(status: [ :cancelled, :rejected ])
      .where(schedules: { date: Date.current.. })
      .order(Schedule.arel_table[:date].asc)
  }

  # Definido como el complemento de upcoming para que las dos secciones
  # particionen las órdenes: sin esto, una orden sin schedule (schedule_id es
  # nullable por el dependent: :nullify) se caería de ambas listas.
  scope :history, -> {
    where.not(id: upcoming)
      .left_joins(:schedule)
      .order(Arel.sql("schedules.date DESC NULLS LAST"))
  }
  after_create :assign_account
  after_update_commit :sync_accounts,
    if: -> { saved_change_to_status? || saved_change_to_price? || saved_change_to_discounted_price? }
  after_destroy_commit -> { @accounts_to_sync.each(&:sync_amount!) }

  def self.reserve(consumer:, schedule:, delivery_method:, address:, quantity: 1, notes: nil, discount_percentage: 0)
    gross_price = schedule.menu.price * quantity
    discounted_price = (gross_price * (100 - discount_percentage.clamp(0, 100)) / 100).round(2)
    order = new(consumer:, schedule:, amount: quantity, notes:, address:, price: gross_price, discounted_price:, delivery_method:)

    return order unless order.valid?

    schedule.with_lock do
      if schedule.order_deadline_passed?
        order.errors.add(:schedule_id, I18n.t("validations.order_deadline_passed"))
      elsif schedule.available?(quantity:)
        order.save
      else
        order.errors.add(:schedule_id, I18n.t("validations.schedule_unavailable"))
      end
    end

    order
  end

  def delivery_method_allowed_by_provider
    return if delivery_method.blank? || schedule.blank?
    return if schedule.menu.provider.allows_delivery_method?(delivery_method)

    errors.add(:delivery_method, I18n.t("validations.delivery_method_not_allowed"))
  end

  # El subsidio no se persiste: es lo que la empresa cubre, o sea la diferencia
  # entre lo que vale la vianda y lo que termina pagando el empleado.
  def subsidy
    return if price.nil? || discounted_price.nil?

    price - discounted_price
  end

  # RN-12 y RN-13: un pedido pendiente de confirmación se cancela hasta el día de
  # la entrega inclusive; uno ya confirmado, solo mientras la entrega siga siendo
  # para un día futuro. Devuelve el motivo del bloqueo para que la pantalla lo
  # explique. La fecha se mira en los dos estados porque esto es la única guarda
  # del endpoint: que la pantalla esconda el botón no frena un PATCH directo.
  def cancellation_block_reason
    return "already_closed" unless pending? || confirmed?
    return "unavailable" if schedule.nil?
    return if schedule.date.after?(Date.current)
    return if pending? && schedule.date.today?

    schedule.date.today? ? "confirmed_for_today" : "already_closed"
  end

  def cancellable?
    cancellation_block_reason.nil?
  end

  # El lock no es por dinero: evita que un doble envío cancele dos veces y pise
  # el registro de quién y cuándo lo hizo.
  def cancel(by:)
    with_lock do
      return false unless cancellable?

      update(status_before_cancellation: status, status: :cancelled, cancelled_at: Time.current, cancelled_by: by)
    end
  end

  private

  # Asignarse a la cuenta actual del usuario, o crearla si no existiera
  # Forzar a que la cuenta recalcule su valor calculado.
  def assign_account
    unless accounts.empty?
      accounts.each &:sync_amount!
      return
    end

    # Obetener información de la cuenta a la que debería ser asignada la orden:
    # el mes actual y la id del proveedor correspondiente a la orden.
    # Habría que validar si queremos que el pedido se descuente en el mes en el que
    # será enviado, que puede ser distinto del actual. En ese caso, habría que cambiar
    # la siguiente línea por:
    #   month = Schedule.date.beginning_of_month
    month = Date.current.beginning_of_month
    provider =
      self.provider or raise "La orden #{id} no tiene proveedor. Puede ser que no tenga un schedule asignado, que su schedule no tenga un menú o que ese menú no tenga un proveedor"

    account = consumer.accounts.find_or_create_by! month: month, provider: provider
    accounts << account

    account.sync_amount!
  end

  def sync_accounts
    accounts.each(&:sync_amount!)
  end

  def remember_accounts
    @accounts_to_sync = accounts.to_a
  end
end

# == Schema Information
#
# Table name: orders
#
#  id                         :bigint           not null, primary key
#  address                    :string
#  amount                     :integer
#  cancelled_at               :datetime
#  delivery_method            :integer          not null
#  discounted_price           :decimal(10, 2)
#  notes                      :string
#  price                      :decimal(10, 2)
#  status                     :integer          default(0), not null
#  status_before_cancellation :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  cancelled_by_id            :bigint
#  consumer_id                :bigint           not null
#  schedule_id                :bigint
#
# Indexes
#
#  index_orders_on_cancelled_by_id  (cancelled_by_id)
#  index_orders_on_consumer_id      (consumer_id)
#  index_orders_on_schedule_id      (schedule_id)
#
# Foreign Keys
#
#  fk_rails_...  (cancelled_by_id => users.id)
#  fk_rails_...  (consumer_id => consumers.id)
#  fk_rails_...  (schedule_id => schedules.id)
#
