# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::Import::Row do
  # Las claves vienen de la planilla, así que son texto: se pasan sueltas y el
  # resto de la fila lo completa el plato de ejemplo.
  def row(number: 7, **values)
    described_class.new(number: number, values: complete.merge(values))
  end

  let(:complete) do
    {
      "nombre" => "Milanesa con papas fritas",
      "descripcion" => "Milanesa con guarnición de papas",
      "precio" => "320"
    }
  end

  describe "una fila completa" do
    it "arma los atributos que espera Menus::Create" do
      expect(row.attributes).to include(
        name: "Milanesa con papas fritas",
        description: "Milanesa con guarnición de papas",
        price: 320
      )
    end

    it "no tiene errores" do
      expect(row).to be_valid
    end

    it "conserva el número de fila del archivo" do
      expect(row(number: 12).number).to eq(12)
    end
  end

  describe "los grupos de opciones" do
    it "toma un grupo por columna y marca como obligatorio el que lleva asterisco" do
      groups = row(
        "opciones_1" => "Proteína*=carne, pollo",
        "opciones_2" => "Salsa=filetto, crema"
      ).option_groups

      expect(groups).to eq([
        { name: "Proteína", options: [ "carne", "pollo" ], required: true, limit: 1 },
        { name: "Salsa", options: [ "filetto", "crema" ], required: false, limit: 1 }
      ])
    end

    it "deja que el empleado elija una opción por grupo: el resto se ajusta en la aplicación" do
      groups = row("opciones_1" => "Salsa=filetto, crema, bolognesa").option_groups

      expect(groups.sole[:limit]).to eq(1)
    end

    it "ignora las columnas de opciones vacías" do
      expect(row("opciones_1" => "", "opciones_3" => "   ").option_groups).to be_empty
    end

    it "avisa cuando no se entiende el grupo" do
      errors = row("opciones_1" => "pollo y papas").errors

      expect(errors).to eq([ I18n.t("validations.menu_import.options", cell: "pollo y papas") ])
    end

    it "avisa cuando un grupo repite una opción" do
      errors = row("opciones_1" => "Salsa=filetto, FILETTO").errors

      expect(errors).to eq([ I18n.t("validations.menu_import.duplicated_options", name: "Salsa") ])
    end
    it "limpia espacios en blanco alrededor del nombre y las opciones" do
      groups = row("opciones_1" => "  Proteína * = carne ,  pollo  ").option_groups

      expect(groups).to eq([
        { name: "Proteína", options: [ "carne", "pollo" ], required: true, limit: 1 }
      ])
    end
  end

  describe "lo que falta en la fila" do
    it "pide el nombre" do
      expect(row("nombre" => "  ").errors).to eq([ I18n.t("validations.menu_import.name") ])
    end

    it "pide la descripción" do
      expect(row("descripcion" => "").errors).to eq([ I18n.t("validations.menu_import.description") ])
    end

    it "pide un precio mayor que cero" do
      expect(row("precio" => "0").errors).to eq([ I18n.t("validations.menu_import.price") ])
      expect(row("precio" => "-15").errors).to eq([ I18n.t("validations.menu_import.price") ])
    end

    it "pide un precio que sea un número sin símbolos" do
      expect(row("precio" => "gratis").errors).to eq([ I18n.t("validations.menu_import.price") ])
      expect(row("precio" => "$320").errors).to eq([ I18n.t("validations.menu_import.price") ])
    end

    it "rechaza celdas de opciones con formato inválido o vacías" do
      [ "Salsa=", "=filetto", "Salsa" ].each do |cell|
        expect(row("opciones_1" => cell).errors)
          .to include(I18n.t("validations.menu_import.options", cell: cell))
      end
    end

    it "junta todo lo que falta en la misma fila" do
      expect(row("nombre" => "", "precio" => "").errors.size).to eq(2)
    end

    it "conserva el número de fila para poder señalarla" do
      expect(row(number: 12).number).to eq(12)
    end
  end

  describe "lo que la planilla ya no pregunta" do
    it "no pide días ni fechas: la agenda se arma después, desde la aplicación" do
      expect(row("lunes" => "", "desde" => "", "cupo" => "")).to be_valid
    end
  end

  describe "los valores que llegan como número" do
    it "acepta el precio tal como lo guarda una planilla de cálculo" do
      expect(row("precio" => 320.5).attributes[:price]).to eq(320.5)
    end
  end
end
