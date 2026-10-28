# frozen_string_literal: true

module Menus
  module Import
    # Lee la planilla que sube el proveedor y devuelve una fila por plato, con
    # el número de línea para poder señalar los errores donde el proveedor los
    # ve. Ver docs/importar-menu.md.
    class Sheet
      EXTENSIONS = { ".xlsx" => :xlsx, ".xls" => :xls, ".csv" => :csv, ".ods" => :ods }.freeze
      MAX_ROWS = 200
      HELP_PREFIX = "#"
      BOM = "﻿"

      class UnsupportedFormat < StandardError; end
      class Unreadable < StandardError; end
      class TooManyRows < StandardError; end

      def initialize(path:, filename: nil)
        @path = path.to_s
        @extension = EXTENSIONS[File.extname(filename || @path).downcase] or raise UnsupportedFormat
      end

      # Pares [número de fila, valores por encabezado]. La primera fila que no es
      # ayuda ni está vacía hace de encabezado: así la planilla puede traer
      # explicaciones arriba sin que haya que contarlas.
      def rows
        @rows ||= begin
          numbered = significant_rows
          raise Unreadable if numbered.empty?

          _, header = numbered.shift
          raise TooManyRows if numbered.size > MAX_ROWS

          @headers = normalize(header)
          numbered.map { |number, values| [ number, @headers.zip(values).to_h ] }
        end
      end

      # Los encabezados que trajo la planilla, para avisar si falta una columna.
      def headers
        rows
        @headers
      end

      private

      def significant_rows
        (sheet.first_row..sheet.last_row)
          .map { |number| [ number, sheet.row(number) ] }
          .reject { |_, values| blank?(values) || help?(values) }
      end

      # roo descarta la primera fila si se usa parse sin argumentos, porque la
      # toma como encabezado: por eso se lee fila por fila.
      def sheet
        @sheet ||= Roo::Spreadsheet.open(@path, extension: @extension)
      rescue StandardError
        raise Unreadable
      end

      # Excel guarda los CSV con un BOM al principio. Sin sacarlo, el primer
      # encabezado no sería "nombre" y la planilla parecería incompleta.
      def normalize(values)
        values.map { it.to_s.delete_prefix(BOM).strip.downcase }
      end

      def blank?(values)
        values.all? { it.to_s.strip.empty? }
      end

      def help?(values)
        values.first.to_s.strip.start_with?(HELP_PREFIX)
      end
    end
  end
end
