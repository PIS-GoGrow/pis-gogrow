# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Importar menú desde planilla", type: :system do
  fixtures :users, :providers, :menus, :menu_option_groups, :schedules

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }
  let(:valid_csv) { Rails.root.join("public/plantillas/menu.csv") }

  def write_temp_csv(contents)
    Rails.root.join("tmp", "menu_test_#{SecureRandom.hex(4)}.csv").tap do |path|
      File.write(path, contents)
    end
  end

  before do
    sign_in provider_user, role: :provider
  end

  it "permite descargar la plantilla, previsualizar los platos y confirmar la importación" do
    visit_hydrated schedules_path

    click_on "Importar platos"

    expect(page).to have_current_path(provider_menu_import_path)
    expect(page).to have_content("Importar platos")
    expect(page).to have_content("Cómo importar tu menú")

    # Verifica enlace de plantilla
    expect(page).to have_link("Descargar plantilla", href: "/plantillas/menu.csv")

    # Adjunta la planilla válida
    attach_file("file", valid_csv, make_visible: true)
    expect(page).to have_content("menu.csv")

    # Pide la vista previa
    click_on "Ver qué se va a importar"

    # Verifica el resumen de vista previa
    expect(page).to have_content("Vista previa")
    expect(page).to have_content("2 para crear · 1 para actualizar")
    expect(page).to have_content("Milanesa con papas fritas")
    expect(page).to have_content("Actualiza")
    expect(page).to have_content("Sorrentinos")
    expect(page).to have_content("Ensalada César")
    expect(page).to have_content("Nuevo")

    # Confirma la importación
    expect(page).to have_button("Confirmar importación")
    expect {
      click_on "Confirmar importación"
      expect(page).to have_current_path(schedules_path(tab: "saved"))
    }.to change { provider.menus.saved.count }.by(2)

    # Verifica mensaje de éxito y datos persistidos
    expect(page).to have_content(I18n.t("flash.menu_imported", count: 3))

    expect(provider.menus.saved.find_by(name: "Milanesa con papas fritas").price).to eq(320)
    expect(provider.menus.saved.find_by(name: "Sorrentinos")).to be_present
    expect(provider.menus.saved.find_by(name: "Ensalada César")).to be_present
  end

  it "muestra los errores por fila cuando la planilla es inválida y bloquea la confirmación" do
    invalid_csv = write_temp_csv(<<~CSV)
      nombre,descripcion,precio,cupo,lunes
      Tarta de acelga,Casera y sana,-10,15,x
    CSV

    visit_hydrated provider_menu_import_path

    attach_file("file", invalid_csv, make_visible: true)
    click_on "Ver qué se va a importar"

    expect(page).to have_content("Tarta de acelga")
    expect(page).to have_content("Fila 2")
    expect(page).to have_content("El precio tiene que ser un número mayor que cero.")
    expect(page).to have_content("Hay que corregir la planilla")
    expect(page).to have_content("No se importa ningún plato hasta que todas las filas estén bien.")

    expect(page).to have_no_button("Confirmar importación")
    expect(provider.menus.where(name: "Tarta de acelga")).to be_empty
  ensure
    FileUtils.rm_f(invalid_csv) if invalid_csv
  end
end
