# frozen_string_literal: true

# Representa un pedido hecho por un consumidor a un menú. Se relaciona con la
# publicación de ese menú (su schedule) y no con el menú en sí.
# Antes crearse, debería relacionarse con un schedule y un consumer. Si es así,
# la cuenta se le asigna automáticamente. Las cuentas de una orden no deberían
# asignarse manualmente.
class Order < ApplicationRecord
  # La migración 20260911234117 usa el modelo Order, así que al reconstruir la
  # base desde cero el enum se evalúa antes de que exista su columna.
  attribute :delivery_method, :integer
  attribute :status_before_cancellation, :integer

  enum :status, { pending: 0, confirmed: 1, cancelled: 2, rejected: 3 }, default: :pending
  enum :delivery_method, { office: 0, home: 1 }
  enum :status_before_cancellation, { pending: 0, confirmed: 1 }, prefix: :before_cancellation
  enum :rejection_reason, {
    out_of_stock: 0,
    duplicate_order: 1,
    customer_request: 2,
    order_error: 3,
    other: 4,
    dish_modified: 5
  }, prefix: :rejection_reason

  # Esta línea tiene que estar antes de has_many :order_accounts.
  # Antes de que se borre la orden, se tiene que registrar sus cuentas
  # asociadas para que estas actualicen su monto.
  before_destroy :remember_accounts
  # El pedido conserva el plato tal como estaba al pedirlo: editarlo después no
  # tiene que reescribir el historial.
  before_create :snapshot_menu

  belongs_to :consumer
  belongs_to :schedule
  belongs_to :cancelled_by, class_name: "User", optional: true
  belongs_to :modified_by, class_name: "User", optional: true
  has_one :menu, through: :schedule
  has_one :provider, through: :menu

  has_many :order_accounts, dependent: :destroy
  has_many :accounts, through: :order_accounts

  has_many :order_benefits, dependent: :destroy
  has_many :benefits, through: :order_benefits

  # El mensaje de aclaraciones es opcional: la pantalla manda "" cuando el
  # empleado no escribe nada, y sin esto el pedido queda con un string vacío que
  # las vistas no distinguen de un nil (muestran "Notas" en vez de "Sin notas").
  normalizes :notes, with: ->(value) { value.presence }

  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :discounted_price, comparison: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price, comparison: { greater_than_or_equal_to: 0 }, presence: true
  validates :address, presence: true, if: :home?
  validates :delivery_method, presence: true
  validates :rejection_reason, presence: true, if: :rejected?
  validates :rejection_details, presence: true, if: -> { rejected? && rejection_reason_other? }
  validate :delivery_method_allowed_by_provider, on: :create
  # Solo al crear o cuando el empleado toca la selección: un pedido anterior a
  # esta funcionalidad no tiene elección guardada, y el proveedor tiene que
  # poder confirmarlo igual.
  validate :selected_options_offered_by_menu, if: -> { new_record? || selected_options_changed? }

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
    where.not(id: upcoming.reorder(nil).select(:id))
      .left_joins(:schedule)
      .order(Arel.sql("schedules.date DESC NULLS LAST"))
  }
  after_create :ensure_accounts!
  after_update_commit :sync_accounts,
    if: -> { saved_change_to_status? || saved_change_to_price? || saved_change_to_discounted_price? }
  after_destroy_commit -> { @accounts_to_sync.each(&:sync_amount!) }

  # Notificaciones al consumidor cuando cambia el estado de la orden
  after_update_commit :notify_confirmed, if: -> { saved_change_to_status? && confirmed? }
  after_update_commit :notify_rejected, if: -> { saved_change_to_status? && rejected? }

  # Inicializa una orden con el precio que calculó OrderPricing. benefits es
  # { Benefit => viandas que cubre }; sin discounted_price se cobra el precio de
  # lista.
  def self.reserve(
    consumer:,
    schedule:,
    delivery_method:,
    address:,
    quantity: 1,
    notes: nil,
    discounted_price: nil,
    selected_options: [],
    benefits: {}
  )
    price = schedule.menu.price * quantity

    order = new(
      consumer:,
      schedule:,
      amount: quantity,
      notes:,
      address:,
      price:,
      discounted_price: discounted_price || price,
      delivery_method:,
      selected_options:
    )

    benefits.each do |benefit, benefit_used|
      order.apply_benefit benefit, benefit_used
    end

    return order unless order.valid?

    schedule.with_lock do
      if schedule.order_deadline_passed?
        order.errors.add(:schedule_id, I18n.t("validations.order_deadline_passed"))
      elsif schedule.available?(quantity:)
        order.save
      else
        order.errors.add(
          :schedule_id,
          I18n.t("validations.schedule_unavailable")
        )
      end
    end

    order
  end

  def apply_benefit(benefit, benefit_used)
    order_benefits.new benefit:, benefit_used:
  end

  def apply_benefit!(benefit, benefit_used)
    order_benefits.create! benefit:, benefit_used:
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

  # Confirmar solo corre sobre pedidos pendientes; rechazar también sobre los
  # confirmados, porque el proveedor puede no poder cumplir lo que aceptó. Un
  # pedido cancelado o ya rechazado no se toca: pisaría la cancelación del
  # empleado. El lock es por el doble envío, igual que en cancel.
  def decide(status, reason: nil, details: nil)
    with_lock do
      return false unless pending? || (confirmed? && status.to_s == "rejected")

      attrs = { status: status }
      if status.to_s == "rejected"
        attrs[:rejection_reason] = reason
        attrs[:rejection_details] = details
      end

      update(attrs)
    end
  end

  # RN-12: modificar equivale a cancelar y volver a pedir, así que rige la misma
  # ventana. Una orden ya confirmada queda fuera: el proveedor la aceptó con
  # esos datos. Devuelve el motivo del bloqueo para que la pantalla lo explique.
  def modification_block_reason
    return "already_confirmed" if confirmed?
    return "already_closed" unless pending?
    return "unavailable" if schedule.nil?
    return if schedule.date >= Date.current

    "already_closed"
  end

  def modifiable?
    modification_block_reason.nil?
  end

  # El cupo del schedule y los beneficios ya cuentan las unidades de esta orden,
  # así que hay que devolvérselas antes de validar y de repartir el subsidio
  # sobre el total nuevo: sin eso, pasar de 2 a 3 se rechazaría contra su propio
  # consumo. El consumidor se bloquea primero, como al crear el carrito, para
  # que dos pedidos simultáneos no gasten los mismos usos de un beneficio.
  def modify(by:, quantity:, notes:, delivery:, selected_options: nil)
    transaction do
      consumer.lock!

      with_lock do
        return false unless modifiable?

        schedule.with_lock do
          if schedule.order_deadline_passed?
            errors.add(:base, I18n.t("validations.order_deadline_passed"))
            return false
          end

          # Bajar o mantener cantidad no cuenta como pedir "de más": solo se
          # bloquea si la publicación está agotada y encima se pide aumentar.
          if schedule.remaining_amount + amount.to_i < quantity ||
             (!schedule.available && quantity > amount.to_i)
            errors.add(:base, I18n.t("validations.schedule_unavailable"))
            return false
          end

          line = OrderPricing.new(consumer, held_by: self).call([ { schedule:, quantity: } ]).first

          # El update tiene que ir antes de tocar los beneficios y cortar si
          # falla: si una validación rechaza el cambio, los beneficios no se
          # tocan y modify tiene que devolver false para que el controller
          # reporte el error en vez de un "Pedido actualizado".
          saved = update(
            amount: quantity,
            notes:,
            price: line.price,
            discounted_price: line.discounted_price,
            selected_options: selected_options || self.selected_options,
            modified_at: Time.current,
            modified_by: by,
            **delivery
          )

          return false unless saved

          replace_benefits! line.benefits
          true
        end
      end
    end
  end

  # El tope mensual solo mira las entregas del mes en curso, así que una orden
  # para el mes que viene no tiene unidades que devolver.
  def subsidized_units_held
    return 0 unless schedule&.date&.then { Date.current.all_month.cover?(it) }

    amount.to_i
  end

  # El lock no es por dinero: evita que un doble envío cancele dos veces y pise
  # el registro de quién y cuándo lo hizo.
  def cancel(by:)
    with_lock do
      return false unless cancellable?

      update(status_before_cancellation: status, status: :cancelled, cancelled_at: Time.current, cancelled_by: by)
    end
  end

  # El proveedor retira el plato de una publicación (p. ej. se quedó sin
  # insumos y no puede ofrecerlo). A diferencia de #cancel, esto no respeta la
  # ventana de RN-12/13: esas reglas son sobre cuándo puede cancelar el
  # consumidor, y acá quien decide es el proveedor, por un motivo distinto.
  # Solo protegemos contra cancelar dos veces un pedido ya cerrado.
  # Al retirar el plato también notificamos al consumidor porque su pedido
  # deja de poder cumplirse.
  def withdraw!(by:)
    with_lock do
      return false if cancelled? || rejected?

      notification_data = {
        date: I18n.l(schedule.date, format: :short),
        dish: menu_name,
        provider: provider.user.name
      }

      update!(
        status_before_cancellation: status,
        status: :cancelled,
        cancelled_at: Time.current,
        cancelled_by: by
      )

      Notifier.call(
        event_key: :order_withdrawal,
        user: consumer.user,
        notifiable: self,
        description_data: notification_data
      )

      true
    end
  end

  # Los pedidos creados sin pasar por las validaciones (fixtures, consola) no
  # tienen la copia del plato: para esos se muestra el plato actual.
  def menu_name = super || schedule&.menu&.name
  def menu_description = super || schedule&.menu&.description
  def menu_option_groups = super || schedule&.menu&.option_groups_snapshot || []

  # El proveedor modificó el plato de esta programación y eligió no mantener los
  # pedidos ya confirmados. Igual que #withdraw!, no respeta la ventana de RN-12/13.
  def reject_for_dish_change!
    with_lock do
      return false unless confirmed?

      update!(status: :rejected, rejection_reason: :dish_modified)
    end
  end

  # Asigna la orden a las dos cuentas que le corresponden y las hace recalcular
  # su monto: la del empleado, que paga su parte, y la de su empresa, que paga el
  # subsidio. Es idempotente, así que sirve también para completar las cuentas de
  # órdenes viejas: una orden cuelga siempre de una sola cuenta de cada dueño.
  def ensure_accounts!
    # Descontamos el pedido de la cuenta del mes en el que va a ser enviado
    month = schedule.date.beginning_of_month
    provider =
      self.provider or raise "La orden #{id} no tiene proveedor. Puede ser que no tenga un schedule asignado, que su schedule no tenga un menú o que ese menú no tenga un proveedor"

    [ consumer, consumer.company ].each do |owner|
      account = accounts.find { it.owner_type == owner.class.name && it.owner_id == owner.id } ||
                account_of(owner, month:, provider:)
      accounts << account unless accounts.include?(account)

      account.sync_amount!
    end
  end

  def notify_confirmed
    Notifier.call(
      event_key: :order_confirmation,
      user: consumer.user,
      notifiable: self,
      description_data: {
        date: I18n.l(schedule.date, format: :short),
        provider: provider.user.name
      }
    )
  end

  def notify_rejected
    reason = I18n.t!(
      "notifications.order_rejection.reasons.#{rejection_reason}",
      details: rejection_details
    )

    Notifier.call(
      event_key: :order_rejection,
      user: consumer.user,
      notifiable: self,
      description_data: {
        date: I18n.l(schedule.date, format: :short),
        dish: menu_name,
        provider: provider.user.name,
        reason:
      }
    )
  end

  # El cupo del schedule ya descuenta esta orden, así que el máximo que el
  # empleado puede elegir es lo que queda más lo que ya tiene reservado.
  def max_quantity
    return amount.to_i if schedule.nil?

    schedule.remaining_amount + amount.to_i
  end

  # La dirección actual del pedido se mantiene como opción aunque no esté
  # guardada, para que modificar la cantidad no obligue a cambiarla.
  # Si el proveedor no admite envíos a domicilio, sólo se ofrece la dirección de la oficina.
  def delivery_address_options(consumer)
    return [ { id: "office", label: I18n.t("pages.orders.addresses.office"), address: consumer.company.address } ] unless provider&.home_delivery?

    options = consumer.delivery_address_options
    return options if address.blank? || options.pluck(:address).include?(address)

    options + [ { id: "current", label: I18n.t("pages.orders.addresses.current"), address: address } ]
  end

  private

  # Cada grupo que el plato ofrece tiene que venir una sola vez y con entre 1 y
  # limit opciones, todas del propio grupo. La pantalla ya lo impide, pero esta
  # es la única guarda real: un POST directo no pasa por ella.
  def selected_options_offered_by_menu
    groups = schedule&.menu&.option_groups.to_a
    chosen = Array(selected_options).index_by { it["group_id"].to_i }

    valid = chosen.size == Array(selected_options).size &&
      chosen.keys.sort == groups.map(&:id).sort &&
      groups.all? { chosen_within_group?(chosen[it.id]["values"], it) }

    errors.add(:base, I18n.t("validations.invalid_options")) unless valid
  end

  def chosen_within_group?(values, group)
    values.is_a?(Array) && values.any? && values.size <= group.limit &&
      values.uniq.size == values.size && values.all? { group.options.include?(it) }
  end
  def snapshot_menu
    menu = schedule&.menu
    return if menu.nil?

    self[:menu_name] ||= menu.name
    self[:menu_description] ||= menu.description
    self[:menu_option_groups] ||= menu.option_groups_snapshot
  end

  # La cuenta de la empresa la comparten todos sus empleados, así que dos pedidos
  # simultáneos pueden intentar crearla a la vez. create_or_find_by! inserta en un
  # savepoint: si el índice único rechaza el segundo INSERT, busca la que creó el
  # otro sin abortar la transacción del pedido.
  def account_of(owner, month:, provider:)
    owner.accounts.find_by(month:, provider:) || owner.accounts.create_or_find_by!(month:, provider:)
  end

  # El tope mensual solo mira las entregas del mes en curso, así que una orden
  # para el mes que viene no tiene unidades que devolver.
  def subsidized_units_held
    return 0 unless schedule&.date&.then { Date.current.all_month.cover?(it) }

    order_benefits.sum(:benefit_used)
  end

  def replace_benefits!(benefits)
    order_benefits.where.not(benefit_id: benefits.keys.map(&:id)).destroy_all
    benefits.each do |benefit, benefit_used|
      order_benefits.find_or_initialize_by(benefit:).update!(benefit_used:)
    end
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
#  menu_description           :string
#  menu_name                  :string
#  menu_option_groups         :jsonb
#  modified_at                :datetime
#  notes                      :string
#  price                      :decimal(10, 2)
#  rejection_details          :string
#  rejection_reason           :integer
#  selected_options           :jsonb            not null
#  status                     :integer          default(0), not null
#  status_before_cancellation :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  cancelled_by_id            :bigint
#  consumer_id                :bigint           not null
#  modified_by_id             :bigint
#  schedule_id                :bigint
#
# Indexes
#
#  index_orders_on_cancelled_by_id  (cancelled_by_id)
#  index_orders_on_consumer_id      (consumer_id)
#  index_orders_on_modified_by_id   (modified_by_id)
#  index_orders_on_schedule_id      (schedule_id)
#
# Foreign Keys
#
#  fk_rails_...  (cancelled_by_id => users.id)
#  fk_rails_...  (consumer_id => consumers.id)
#  fk_rails_...  (modified_by_id => users.id)
#  fk_rails_...  (schedule_id => schedules.id)
#
