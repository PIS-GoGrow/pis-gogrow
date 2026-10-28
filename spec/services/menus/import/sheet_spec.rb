# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::Import::Sheet do
  def write(contents, name: "menu.csv")
    path = Rails.root.join("tmp", name)
    File.write(path, contents)
    path
  end

  it "lee la plantilla que se le ofrece al proveedor" do
    sheet = described_class.new(path: Rails.root.join("public/plantillas/menu.csv"))

    expect(sheet.rows.size).to eq(3)
    expect(sheet.headers.first(4)).to eq(%w[nombre descripcion precio opciones_1])

    _number, first = sheet.rows.first
    expect(first["nombre"]).to eq("Milanesa con papas fritas")
    expect(first["opciones_1"]).to eq("Proteína*=carne, pollo")
  end

  it "descarta las filas de ayuda y toma la primera fila útil como encabezado" do
    path = write(<<~CSV)
      "# Una explicación arriba de todo"
      "# Otra más"
      nombre,precio
      Milanesa,320
    CSV

    _number, row = described_class.new(path: path).rows.sole

    expect(row).to eq("nombre" => "Milanesa", "precio" => "320")
  end

  it "conserva el número de fila del archivo, para poder señalar los errores" do
    path = write(<<~CSV)
      "# Ayuda"
      nombre,precio
      Milanesa,320
      Sorrentinos,380
    CSV

    expect(described_class.new(path: path).rows.map(&:first)).to eq([ 3, 4 ])
  end

  it "ignora las filas vacías del medio" do
    path = write(<<~CSV)
      nombre,precio
      Milanesa,320
      ,
      Sorrentinos,380
    CSV

    expect(described_class.new(path: path).rows.size).to eq(2)
  end

  it "normaliza los encabezados a minúscula y sin espacios" do
    path = write(<<~CSV)
      " Nombre ",PRECIO
      Milanesa,320
    CSV

    _number, row = described_class.new(path: path).rows.sole

    expect(row.keys).to eq(%w[nombre precio])
  end

  it "acepta los formatos que exporta una planilla de cálculo" do
    %w[menu.xlsx menu.xls menu.csv menu.ods].each do |name|
      expect { described_class.new(path: "/tmp/#{name}") }.not_to raise_error
    end
  end

  it "rechaza un formato que no se puede leer" do
    expect { described_class.new(path: "/tmp/menu.pdf") }
      .to raise_error(described_class::UnsupportedFormat)
  end

  it "lee un .xls, que es lo que exporta Excel por defecto en muchas instalaciones" do
    book = Spreadsheet::Workbook.new
    page = book.create_worksheet
    page.row(0).concat %w[nombre descripcion precio]
    page.row(1).concat [ "Milanesa", "Con papas", "320" ]
    path = Rails.root.join("tmp", "sheet_spec.xls")
    book.write(path)

    _number, row = described_class.new(path: path).rows.sole

    expect(row).to eq("nombre" => "Milanesa", "descripcion" => "Con papas", "precio" => "320")
  end

  it "ignora el BOM con el que Excel guarda los CSV" do
    path = write("﻿nombre,precio\nMilanesa,320\n", name: "bom.csv")

    expect(described_class.new(path: path).headers).to eq(%w[nombre precio])
  end

  it "usa el nombre original para decidir el formato, no el del archivo temporal" do
    expect { described_class.new(path: "/tmp/RackMultipart20261021", filename: "mi menú.csv") }
      .not_to raise_error
  end

  it "avisa cuando el archivo no se puede leer" do
    path = write("no soy una planilla", name: "roto.csv")
    allow(Roo::Spreadsheet).to receive(:open).and_raise(StandardError)

    expect { described_class.new(path: path).rows }.to raise_error(described_class::Unreadable)
  end

  it "avisa cuando la planilla tiene más filas de las permitidas" do
    stub_const("#{described_class}::MAX_ROWS", 2)
    path = write(<<~CSV)
      nombre,precio
      Milanesa,320
      Sorrentinos,380
      Ensalada,290
    CSV

    expect { described_class.new(path: path).rows }.to raise_error(described_class::TooManyRows)
  end
end
