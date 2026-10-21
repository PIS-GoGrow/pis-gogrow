# frozen_string_literal: true

module Menus
  module Import
    # Una fila de la planilla traducida a lo que espera Menus::Create: los
    # atributos del plato y la agenda con la que se programa. Valida acá lo que
    # el modelo no puede explicar con el número de fila a la vista.
    # Ver docs/importar-menu.md.
    class Row
      WEEKDAYS = { "lunes" => 1, "martes" => 2, "miercoles" => 3, "jueves" => 4, "viernes" => 5 }.freeze
      OPTION_COLUMNS = (1..10).map { "opciones_#{it}" }.freeze
      MARKED = %w[x si sí true 1].freeze
      REQUIRED_MARK = "*"
      DEFAULT_LIMIT = 1

      attr_reader :number

      def initialize(number:, values:)
        @number = number
        @values = values.to_h { |key, value| [ key.to_s.strip.downcase, value ] }
      end

      def name = text("nombre")

      def valid? = errors.empty?

      # Un mensaje por problema, ya redactado: la vista previa los muestra tal
      # cual junto al número de fila.
      def errors
        @errors ||= [
          (message(:name) if name.blank?),
          (message(:description) if text("descripcion").blank?),
          (message(:price) unless price&.positive?),
          (message(:amount) unless amount&.positive? && amount <= Schedule::MAX_AMOUNT),
          (message(:weekdays) if weekdays.empty?),
          (message(:limit) unless limit.positive?),
          (message(:starts_on) if @values["desde"].present? && starts_on.nil?),
          (message(:ends_on) if @values["hasta"].present? && ends_on.nil?),
          (message(:range) if ends_on && starts_on && ends_on < starts_on),
          (message(:past) if starts_on && starts_on < Date.current),
          *option_errors
        ].compact
      end

      def attributes
        {
          name: name,
          description: text("descripcion"),
          price: price,
          option_groups_attributes: option_groups
        }
      end

      def agenda
        {
          mode: ends_on ? "range" : "weekly",
          starts_on: (starts_on || default_start).to_s,
          ends_on: ends_on&.to_s,
          amount: amount,
          weekdays: weekdays
        }
      end

      def weekdays
        WEEKDAYS.filter_map { |column, number| number if marked?(@values[column]) }
      end

      def option_groups
        option_cells.filter_map { |cell| parse_group(cell) }
      end

      private

      def text(column) = @values[column].to_s.strip

      def price = decimal("precio")

      def amount = integer("cupo")

      def limit = integer("limite") || DEFAULT_LIMIT

      def starts_on = date("desde")

      def ends_on = date("hasta")

      # Sin fecha, la semana próxima: importar un menú es planificar lo que
      # viene, no pisar lo que ya está publicado.
      def default_start = Date.current.next_week(:monday)

      def option_cells
        OPTION_COLUMNS.filter_map { |column| text(column).presence }
      end

      def option_errors
        option_cells.filter_map do |cell|
          group = parse_group(cell)

          next message(:options, cell: cell) if group.nil?

          options = group[:options].map { it.downcase }
          message(:duplicated_options, name: group[:name]) if options.uniq.size != options.size
        end
      end

      def message(key, **data) = I18n.t("validations.menu_import.#{key}", **data)

      # "Proteína*=carne, pollo" -> grupo obligatorio con dos opciones. El
      # asterisco va pegado al nombre y las opciones se separan por coma, igual
      # que en el formulario de la aplicación.
      def parse_group(cell)
        name, options = cell.split("=", 2)
        name = name.to_s.strip
        required = name.end_with?(REQUIRED_MARK)
        name = name.delete_suffix(REQUIRED_MARK).strip
        options = options.to_s.split(",").map(&:strip).reject(&:empty?)

        return if name.empty? || options.empty?

        { name: name, options: options, required: required, limit: [ limit, options.size ].min }
      end

      def marked?(value) = MARKED.include?(value.to_s.strip.downcase)

      def decimal(column)
        value = @values[column]
        return value.to_d if value.is_a?(Numeric)

        BigDecimal(text(column))
      rescue ArgumentError, TypeError
        nil
      end

      def integer(column)
        value = @values[column]
        return value.to_i if value.is_a?(Numeric)

        Integer(text(column))
      rescue ArgumentError, TypeError
        nil
      end

      def date(column)
        value = @values[column]
        return value.to_date if value.respond_to?(:to_date) && !value.is_a?(String)

        Date.iso8601(text(column))
      rescue Date::Error, NoMethodError
        nil
      end
    end
  end
end
