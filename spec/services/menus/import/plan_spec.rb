# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::Import::Plan do
  def write(contents, name: "plan_spec.csv")
    path = Rails.root.join("tmp", name)
    File.write(path, contents)
    path
  end

  # Una planilla mínima con el encabezado nuevo: nombre, descripción, precio y
  # las columnas de opciones que haga falta.
  def sheet_with(*rows)
    write(([ "nombre,descripcion,precio,opciones_1" ] + rows).join("\n") + "\n")
  end

  def plan_for(path) = described_class.new(path: path).tap(&:call)

  describe "la plantilla que se le ofrece al proveedor" do
    let(:plan) { plan_for(Rails.root.join("public/plantillas/menu.csv")) }

    it "se lee entera" do
      expect(plan.call).to be(true)
      expect(plan.error).to be_nil
      expect(plan.entries.map(&:name))
        .to eq([ "Milanesa con papas fritas", "Sorrentinos", "Ensalada César" ])
    end

    it "trae cada plato con lo que la tarjeta necesita mostrar" do
      entry = plan.entries.second

      expect(entry).to have_attributes(number: 9, name: "Sorrentinos", price: 380)
      expect(entry.option_groups.map { it[:name] }).to eq([ "Relleno", "Salsa" ])
      expect(entry).to be_valid
    end
  end

  describe "las filas con problemas" do
    it "las marca sin frenar a las demás" do
      plan = plan_for(sheet_with("Milanesa,Con papas,320,", "Sorrentinos,Con salsa,,"))

      expect(plan.call).to be(true)
      expect(plan.entries.map(&:valid?)).to eq([ true, false ])
      expect(plan.entries.second.errors).to eq([ I18n.t("validations.menu_import.price") ])
    end

    it "no se queja de un nombre repetido: duplicar un plato es válido" do
      plan = plan_for(sheet_with("Milanesa,Con papas,320,", "milanesa,Con puré,340,"))

      expect(plan.entries.map(&:valid?)).to eq([ true, true ])
    end
  end

  describe "los errores del archivo" do
    it "rechaza un formato que no se puede leer" do
      expect(plan_for("/tmp/menu.pdf").error)
        .to eq(I18n.t("validations.menu_import.file.unsupported_format"))
    end

    it "avisa cuando falta una columna obligatoria" do
      path = write("nombre,precio\nMilanesa,320\n")

      expect(plan_for(path).error)
        .to eq(I18n.t("validations.menu_import.file.missing_columns", columns: "descripcion"))
    end

    it "no pide más las columnas de días ni de cupo" do
      expect(plan_for(sheet_with("Milanesa,Con papas,320,")).error).to be_nil
    end

    it "avisa cuando la planilla no tiene platos" do
      expect(plan_for(sheet_with).error).to eq(I18n.t("validations.menu_import.file.empty"))
    end

    it "avisa cuando el archivo no se puede abrir" do
      expect(plan_for("/tmp/no-existe.csv").error)
        .to eq(I18n.t("validations.menu_import.file.unreadable"))
    end

    it "avisa cuando la planilla tiene más platos de los permitidos" do
      stub_const("Menus::Import::Sheet::MAX_ROWS", 1)
      plan = plan_for(sheet_with("Milanesa,Con papas,320,", "Tarta,De verdura,290,"))

      expect(plan.error).to eq(I18n.t("validations.menu_import.file.too_many_rows", max: 1))
    end

    it "rechaza un archivo demasiado grande" do
      path = write("nombre,descripcion,precio\nMilanesa,#{"a" * described_class::MAX_SIZE},320\n", name: "grande.csv")

      expect(plan_for(path).error)
        .to eq(I18n.t("validations.menu_import.file.too_big", max: 5))
    ensure
      File.delete(path)
    end

    it "rechaza un archivo demasiado grande antes de procesar la planilla" do
      path = write("nombre,descripcion,precio\nMilanesa,#{"a" * described_class::MAX_SIZE},320\n", name: "grande2.csv")
      expect(Menus::Import::Sheet).not_to receive(:new)

      plan_for(path).call
    ensure
      File.delete(path)
    end
  end
end
