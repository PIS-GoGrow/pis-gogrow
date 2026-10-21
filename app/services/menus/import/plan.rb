# frozen_string_literal: true

module Menus
  module Import
    # Lo que la planilla va a hacer, antes de tocar nada: una entrada por fila,
    # con la acción que le toca —crear el plato o actualizar el del mismo
    # nombre— y sus errores. Es lo que muestra la vista previa y lo que guarda
    # Menus::Import::Save. Ver docs/importar-menu.md.
    class Plan
      REQUIRED_COLUMNS = %w[nombre descripcion precio cupo].freeze
      MAX_SIZE = 2.megabytes

      Entry = Data.define(:number, :name, :action, :errors, :row, :menu) do
        def valid? = errors.empty?
      end

      attr_reader :entries, :error

      def initialize(provider:, path:, filename: nil)
        @provider = provider
        @path = path.to_s
        @filename = filename
        @entries = []
      end

      def call
        @error = file_error
        @entries = build_entries unless @error
        valid?
      end

      # Todo o nada: con un solo error no se importa ninguna fila.
      def valid? = @error.nil? && @entries.any? && @entries.all?(&:valid?)

      def to_create = @entries.select { it.action == :create }
      def to_update = @entries.select { it.action == :update }
      def failed = @entries.reject(&:valid?)

      private

      def build_entries
        seen = []

        sheet.rows.map do |number, values|
          row = Row.new(number:, values:)
          key = row.name.downcase
          repeated = key.present? && seen.include?(key)
          seen << key
          menu = saved_menus[key]

          Entry.new(
            number:,
            name: row.name,
            action: menu ? :update : :create,
            errors: row.errors + (repeated ? [ message(:duplicated_name, name: row.name) ] : []),
            row:,
            menu:
          )
        end
      end

      # Un plato que el proveedor ya tiene guardado se actualiza; la coincidencia
      # es por nombre, sin importar mayúsculas ni espacios de más.
      def saved_menus
        @saved_menus ||= @provider.menus.saved.index_by { it.name.to_s.strip.downcase }
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
