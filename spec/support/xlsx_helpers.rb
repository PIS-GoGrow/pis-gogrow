# frozen_string_literal: true

module XlsxHelpers
  XlsxCell = Data.define(:value, :format, :formula)

  # Un .xlsx es un zip con XML adentro: alcanza rubyzip para leer la primera
  # hoja sin sumar una gema sólo para los specs. Las fechas se reconocen por el
  # formato de la celda, igual que hace Excel.
  def xlsx_cells(binary)
    zip = Zip::File.open_buffer(StringIO.new(binary))
    xml = ->(path) { Nokogiri::XML(zip.read(path)).remove_namespaces! }
    styles = xml.("xl/styles.xml")
    formats = styles.xpath("//numFmts/numFmt").to_h { [ it["numFmtId"], it["formatCode"] ] }
    cell_formats = styles.xpath("//cellXfs/xf").map { formats[it["numFmtId"]] }
    shared = zip.find_entry("xl/sharedStrings.xml") ? xml.("xl/sharedStrings.xml").xpath("//si").map(&:text) : []

    xml.("xl/worksheets/sheet1.xml").xpath("//sheetData/row").map do |row|
      row.xpath("c").each_with_object([]) do |cell, cells|
        cells[xlsx_column(cell["r"])] = xlsx_cell(cell, cell_formats[cell["s"].to_i], shared)
      end
    end
  end

  def xlsx_rows(binary)
    xlsx_cells(binary).map { |row| row.map { it&.value } }
  end

  private

  def xlsx_column(reference)
    reference[/\A[A-Z]+/].chars.reduce(0) { |index, letter| index * 26 + letter.ord - 64 } - 1
  end

  def xlsx_cell(cell, format, shared)
    raw = cell.at_xpath("v")&.text
    value =
      case cell["t"]
      when "inlineStr" then cell.at_xpath("is").text.presence
      when "s" then shared[raw.to_i]
      when "str" then raw
      else
        number = raw&.include?(".") ? raw.to_d : raw&.to_i
        number && format&.match?(/d.*m.*y/i) ? Date.new(1899, 12, 30) + number : number
      end

    XlsxCell.new(value:, format:, formula: cell.at_xpath("f")&.text)
  end
end

RSpec.configure do |config|
  config.include XlsxHelpers
end
