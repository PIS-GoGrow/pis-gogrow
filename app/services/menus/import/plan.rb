# frozen_string_literal: true

module Menus
  module Import
    # Lo que la planilla propone, antes de tocar nada: una entrada por fila con
    # sus datos y sus errores.
    #
    # No decide nada más. Con qué plato guardado coincide cada fila y qué se
    # crea, se actualiza o se ignora se resuelve en la vista previa, donde el
    # proveedor todavía puede cambiarle el nombre a un plato. Así un error en
    # una fila no lo obliga a volver a la planilla. Ver docs/importar-menu.md.
    class Plan
      REQUIRED_COLUMNS = %w[nombre descripcion precio].freeze
      MAX_SIZE = 5.megabytes

      Entry = Data.define(:number, :name, :description, :price, :option_groups, :errors) do
        def valid? = errors.empty?
      end

      attr_reader :entries, :error

      def initialize(path:, filename: nil)
        @path = path.to_s
        @filename = filename
        @entries = []
      end

      # Devuelve si la planilla se pudo leer. Que una fila traiga errores no es
      # un problema del archivo: se muestra y se corrige en la vista previa.
      def call
        @error = file_error
        @entries = build_entries unless @error
        @error.nil?
      end

      private

      def build_entries
        sheet.rows.map do |number, values|
          row = Row.new(number:, values:)

          Entry.new(
            number:,
            name: row.name,
            description: row.description,
            price: row.price,
            option_groups: row.option_groups,
            errors: row.errors
          )
        end
      end

      # Problemas del archivo entero, que dejan la vista previa sin nada que
      # mostrar. Uno solo alcanza para no seguir leyendo.
      def file_error
        sheet # El formato primero: es el problema más fácil de explicar.
        return file_message(:too_big, max: MAX_SIZE / 1.megabyte) if File.size(@path) > MAX_SIZE

        missing = REQUIRED_COLUMNS - sheet.headers
        return file_message(:missing_columns, columns: missing.join(", ")) if missing.any?

        file_message(:empty) if sheet.rows.empty?
      rescue Sheet::UnsupportedFormat
        file_message(:unsupported_format)
      rescue Sheet::TooManyRows
        file_message(:too_many_rows, max: Sheet::MAX_ROWS)
      rescue Sheet::Unreadable, SystemCallError
        file_message(:unreadable)
      end

      def sheet = @sheet ||= Sheet.new(path: @path, filename: @filename)

      def message(key, **data) = I18n.t("validations.menu_import.#{key}", **data)

      def file_message(key, **data) = message("file.#{key}", **data)
    end
  end
end
