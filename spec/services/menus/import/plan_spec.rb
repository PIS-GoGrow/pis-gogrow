# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::Import::Plan do
  fixtures :users, :providers, :menus, :menu_option_groups

  let(:provider) { providers(:tuviandita) }

  def plan_for(path, filename: nil)
    described_class.new(provider:, path:, filename:).tap(&:call)
  end

  def write(contents, name: "plan.csv")
    path = Rails.root.join("tmp", name)
    File.write(path, contents)
    path
  end

  # Una planilla mínima, con los platos que se le pasen como filas.
  def sheet_with(*dishes)
    write(<<~CSV)
      nombre,descripcion,precio,cupo,lunes,desde,limite,opciones_1
      #{dishes.join("\n")}
    CSV
  end

  describe "la plantilla de ejemplo" do
    let(:plan) { plan_for(Rails.root.join("public/plantillas/menu.csv")) }

    it "se puede importar tal como se descarga" do
      expect(plan).to be_valid
      expect(plan.error).to be_nil
    end

    it "actualiza el plato que el proveedor ya tiene guardado y crea los otros" do
      expect(plan.to_update.map(&:name)).to eq([ "Milanesa con papas fritas" ])
      expect(plan.to_create.map(&:name)).to eq([ "Sorrentinos", "Ensalada César" ])
    end

    it "apunta a la fila del archivo, contando las de ayuda" do
      expect(plan.entries.map(&:number)).to eq([ 9, 10, 11 ])
    end

    it "deja a mano el plato que se va a actualizar" do
      expect(plan.to_update.sole.menu).to eq(menus(:milanesa))
    end
  end

  describe "el cruce con los platos guardados" do
    it "no se fija en mayúsculas ni en espacios de más" do
      plan = plan_for(sheet_with("  MILANESA CON PAPAS FRITAS ,Con papas,320,20,x,,,"))

      expect(plan.to_update.sole.menu).to eq(menus(:milanesa))
    end

    it "no toca los platos de otro proveedor" do
      plan = plan_for(sheet_with("Sorrentinos artesanales,Pasta rellena,380,15,x,,,"))

      expect(plan.to_create.map(&:name)).to eq([ "Sorrentinos artesanales" ])
    end

    it "no cruza con un plato archivado" do
      menus(:milanesa).update!(archived_at: Time.current)

      plan = plan_for(sheet_with("Milanesa con papas fritas,Con papas,320,20,x,,,"))

      expect(plan.to_create.map(&:name)).to eq([ "Milanesa con papas fritas" ])
    end
  end

  describe "los errores de las filas" do
    it "no importa nada si una sola fila tiene un error" do
      plan = plan_for(sheet_with(
        "Milanesa,Con papas,320,20,x,,,",
        "Sorrentinos,Con salsa,,15,x,,,"
      ))

      expect(plan).not_to be_valid
      expect(plan.failed.map(&:number)).to eq([ 3 ])
      expect(plan.failed.sole.errors).to include(I18n.t("validations.menu_import.price"))
    end

    it "avisa cuando el mismo plato aparece en dos filas" do
      plan = plan_for(sheet_with(
        "Milanesa,Con papas,320,20,x,,,",
        "milanesa,Con puré,340,10,x,,,"
      ))

      expect(plan.failed.map(&:number)).to eq([ 3 ])
      expect(plan.failed.sole.errors)
        .to include(I18n.t("validations.menu_import.duplicated_name", name: "milanesa"))
    end
  end

  describe "los errores del archivo" do
    it "rechaza un formato que no se puede leer" do
      expect(plan_for("/tmp/menu.xls").error)
        .to eq(I18n.t("validations.menu_import.file.unsupported_format"))
    end

    it "avisa cuando falta una columna obligatoria" do
      path = write("nombre,precio,lunes\nMilanesa,320,x\n")

      expect(plan_for(path).error)
        .to eq(I18n.t("validations.menu_import.file.missing_columns", columns: "descripcion, cupo"))
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
      plan = plan_for(sheet_with("Milanesa,Con papas,320,20,x,,,", "Tarta,De verdura,290,10,x,,,"))

      expect(plan.error)
        .to eq(I18n.t("validations.menu_import.file.too_many_rows", max: 1))
    end

    it "rechaza un archivo demasiado grande" do
      path = write("nombre,descripcion,precio\nMilanesa,#{"a" * described_class::MAX_SIZE},320\n", name: "grande.csv")

      expect(plan_for(path).error)
        .to eq(I18n.t("validations.menu_import.file.too_big", max: 2))
    ensure
      File.delete(path)
    end
  end
end
