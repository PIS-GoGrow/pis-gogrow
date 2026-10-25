# frozen_string_literal: true

module Orders
  # Crea las órdenes de un carrito de forma atómica.
  class Place
    Result = Struct.new(:orders, :error, :record, keyword_init: true) do
      def success? = error.nil?
    end

    # Rechazo de negocio esperado. Cualquier otra excepción es un bug y sube como 500.
    class Rejected < StandardError
      attr_reader :reason, :record

      def initialize(reason, record: nil)
        @reason = reason
        @record = record
        super(reason.to_s)
      end
    end

    # items: [{ schedule_id: Integer|nil, quantity: Integer|nil, benefits:, notes:, options: }]
    def initialize(consumer:, items:, address:)
      @consumer = consumer
      @items = items
      @address = address
    end

    def call
      validate_cart!
      validate_address!

      Result.new(orders: place_orders)
    rescue Rejected => error
      Result.new(error: error.reason, record: error.record)
    end

    private

    # Validar que el carrito no esté vacío, ni ids o cantidades que no son números
    def validate_cart!
      raise Rejected, :empty_cart if @items.empty?
      raise Rejected, :cart_unavailable unless @items.all? { |item| item[:schedule_id].is_a?(Integer) }
      raise Rejected, :invalid_quantity unless @items.all? { |item| item[:quantity].is_a?(Integer) }
    end

    def validate_address!
      # Con delivery_addresses ya se verifica que la dirección no sea blank.
      return if @consumer.delivery_addresses.include?(@address)
      return if valid_new_address?(@consumer, @address)

      raise Rejected, :invalid_address
    end

    def place_orders
      Order.transaction do
        # Impide órdenes concurrentes del mismo consumidor.
        @consumer.lock!

        schedules = lock_schedules
        pricings = Orders::Pricing.new(@consumer).call(pricing_input(schedules))

        # Se resuelve la entrega de todos los ítems antes de crear nada
        deliveries = resolve_deliveries(schedules)

        @items.zip(pricings, deliveries).map do |item, (_, pricing), delivery|
          reserve_order(item, schedules.fetch(item[:schedule_id]), pricing, delivery)
        end
      end
    end

    # Obtiene todos los schedules pedidos y los lockea
    def lock_schedules
      ids = @items.map { |item| item[:schedule_id] }.uniq

      schedules =
        Schedule
          .includes(menu: :provider)
          .where(id: ids, date: Calendar.new.allowed_order_dates)
          .order(:id)
          .lock
          .index_by(&:id)

      # Algún schedule no existe o está fuera del rango de fechas permitido.
      raise Rejected, :cart_unavailable unless schedules.size == ids.size

      schedules
    end

    def pricing_input(schedules)
      @items.map do |item|
        {
          schedule: schedules.fetch(item[:schedule_id]),
          quantity: item[:quantity],
          benefits: item[:benefits]
        }
      end
    end

    # Si el usuario eligió entrega a domicilio pero el proveedor solo entrega en
    # oficina, delivery_for lo cambia (en el carrito ya se le avisó esto).
    def resolve_deliveries(schedules)
      @items.map do |item|
        provider = schedules.fetch(item[:schedule_id]).menu.provider
        delivery = @consumer.delivery_for(provider, @address)

        # Dirección blank en este punto implica que no hay dirección de empresa.
        raise Rejected, :office_address_required if delivery[:address].blank?

        delivery
      end
    end

    def reserve_order(item, schedule, pricing, delivery)
      order = Order.reserve(
        consumer: @consumer,
        schedule:,
        quantity: item[:quantity],
        notes: item[:notes],
        discounted_price: pricing.discounted_price,
        selected_options: selected_options_for(schedule.menu, item[:options]),
        benefits: pricing.benefits,
        **delivery
      )

      raise Rejected.new(:invalid_order, record: order) unless order.persisted?

      order
    end

    # Además de las direcciones conocidas, el carrito puede mandar una que el
    # empleado ingresó sin guardarla para futuros pedidos.
    def valid_new_address?(consumer, address)
      consumer.delivery_address_options.pluck(:address).include?(address) ||
        DeliveryAddress.valid_full_address?(address)
    end

    # El cupo del schedule ya descuenta esta orden, así que el máximo que el
    # empleado puede elegir es lo que queda más lo que ya tiene reservado.
    # Del parámetro solo se confía el id del grupo y los valores: el nombre se toma
    # del plato, así la copia guardada no depende de lo que mande el cliente.
    def selected_options_for(menu, options)
      groups = menu&.option_groups.to_a.index_by(&:id)

      options.to_a.filter_map do |option|
        group = groups[option[:group_id].to_i]
        values = Array(option[:values]).map(&:to_s).compact_blank
        next if group.nil? || values.empty?

        { group_id: group.id, name: group.name, values: }
      end
    end
  end
end
