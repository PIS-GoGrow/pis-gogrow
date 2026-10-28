# frozen_string_literal: true

module Menus
  module Import
    # Una fila de la planilla traducida a los atributos que espera Menus::Create.
    # La planilla no trae agenda: días, cupo y fechas se ajustan después desde la
    # aplicación, así que acá solo se valida lo que la fila misma puede explicar.
    # Ver docs/importar-menu.md.
    class Row
      OPTION_COLUMNS = (1..10).map { "opciones_#{it}" }.freeze
      REQUIRED_MARK = "*"
      # Cuántas opciones puede elegir el empleado en un grupo. La planilla no lo
      # pregunta para no pedirle una columna más al proveedor: se ajusta desde la
      # aplicación, donde el grupo se ve entero.
      DEFAULT_LIMIT = 1

      attr_reader :number

      def initialize(number:, values:)
        @number = number
        @values = values.to_h { |key, value| [ key.to_s.strip.downcase, value ] }
      end

      def name = text("nombre")

      def description = text("descripcion")

      def price = decimal("precio")

      def valid? = errors.empty?

      # Un mensaje por problema, ya redactado: la vista previa los muestra tal
      # cual en la tarjeta del plato, con el motivo a la vista para que el
      # proveedor sepa qué corregir sin abrirla.
      def errors
        @errors ||= [
          (message(:name) if name.blank?),
          (message(:description) if description.blank?),
          (message(:price) unless price&.positive?),
          *option_errors
        ].compact
      end

      def attributes
        {
          name: name,
          description: description,
          price: price,
          option_groups_attributes: option_groups
        }
      end

      def option_groups
        option_cells.filter_map { |cell| parse_group(cell) }
      end

      private

      def text(column) = @values[column].to_s.strip

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

        { name: name, options: options, required: required, limit: [ DEFAULT_LIMIT, options.size ].min }
      end

      def decimal(column)
        value = @values[column]
        return value.to_d if value.is_a?(Numeric)

        BigDecimal(text(column))
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
