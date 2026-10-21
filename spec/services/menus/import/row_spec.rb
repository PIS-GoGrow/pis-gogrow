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
      "precio" => "320",
      "cupo" => "20",
      "lunes" => "x",
      "miercoles" => "X",
      "viernes" => "x"
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

    it "traduce los días marcados al formato de la agenda, de lunes a viernes" do
      expect(row.weekdays).to eq([ 1, 3, 5 ])
    end

    it "programa desde el lunes de la semana próxima cuando no se indica desde" do
      expect(row.agenda).to include(
        mode: "weekly",
        starts_on: Date.current.next_week(:monday).to_s,
        ends_on: nil,
        amount: 20
      )
    end

    it "usa un rango cuando la fila trae hasta" do
      agenda = row("desde" => "2026-11-02", "hasta" => "2026-11-28").agenda

      expect(agenda).to include(mode: "range", starts_on: "2026-11-02", ends_on: "2026-11-28")
    end

    it "no tiene errores" do
      expect(row).to be_valid
    end
  end

  describe "los grupos de opciones" do
    it "toma un grupo por columna y marca como obligatorio el que lleva asterisco" do
      groups = row(
        "opciones_1" => "Proteína*=carne, pollo",
        "opciones_3" => "Salsa=filetto, crema"
      ).option_groups

      expect(groups).to eq([
        { name: "Proteína", options: %w[carne pollo], required: true, limit: 1 },
        { name: "Salsa", options: %w[filetto crema], required: false, limit: 1 }
      ])
    end

    it "sin columnas de opciones, el plato no tiene grupos" do
      expect(row.option_groups).to be_empty
    end

    it "toma el límite de la columna y no lo deja pasar la cantidad de opciones" do
      groups = row("limite" => "3", "opciones_1" => "Agregados=panceta, huevo").option_groups

      expect(groups.sole[:limit]).to eq(2)
    end

    it "rechaza una celda que no se entiende" do
      expect(row("opciones_1" => "carne y pollo").errors)
        .to include(a_string_including("No se entendió el grupo de opciones"))
    end

    it "rechaza opciones repetidas, sin importar mayúsculas" do
      expect(row("opciones_1" => "Proteína=carne, Carne").errors)
        .to include(a_string_including("opciones repetidas"))
    end
  end

  describe "los errores" do
    it "avisa cuando falta el nombre" do
      expect(row("nombre" => " ").errors).to include(I18n.t("validations.menu_import.name"))
    end

    it "avisa cuando falta la descripción" do
      expect(row("descripcion" => "").errors).to include(I18n.t("validations.menu_import.description"))
    end

    it "rechaza un precio que no es un número positivo" do
      [ "0", "-5", "gratis", "" ].each do |value|
        expect(row("precio" => value).errors).to include(I18n.t("validations.menu_import.price"))
      end
    end

    it "rechaza un cupo que no es entero positivo" do
      [ "0", "media docena", "" ].each do |value|
        expect(row("cupo" => value).errors).to include(I18n.t("validations.menu_import.amount"))
      end
    end

    it "pide marcar al menos un día" do
      sin_dias = complete.except("lunes", "miercoles", "viernes")

      expect(described_class.new(number: 2, values: sin_dias).errors)
        .to include(I18n.t("validations.menu_import.weekdays"))
    end

    it "rechaza una fecha mal escrita" do
      expect(row("desde" => "02/11/2026").errors).to include(I18n.t("validations.menu_import.starts_on"))
    end

    it "rechaza un rango invertido" do
      expect(row("desde" => "2026-11-28", "hasta" => "2026-11-02").errors)
        .to include(I18n.t("validations.menu_import.range"))
    end

    it "rechaza una fecha que ya pasó" do
      expect(row("desde" => Date.current.yesterday.to_s).errors)
        .to include(I18n.t("validations.menu_import.past"))
    end

    it "conserva el número de fila para poder señalarla" do
      expect(row(number: 12).number).to eq(12)
    end
  end

  describe "los valores que vienen de un xlsx" do
    it "acepta números y fechas ya tipados, no solo texto" do
      typed = row(
        "precio" => 320.5,
        "cupo" => 20,
        "limite" => 2,
        "desde" => Date.new(2026, 11, 2),
        "opciones_1" => "Salsa=filetto, crema"
      )

      expect(typed.attributes[:price]).to eq(320.5)
      expect(typed.agenda).to include(amount: 20, starts_on: "2026-11-02")
      expect(typed.option_groups.sole[:limit]).to eq(2)
      expect(typed).to be_valid
    end
  end
end
