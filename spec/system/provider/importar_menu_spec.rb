# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Importar menú desde planilla", type: :system do
  fixtures :users, :providers, :menus, :menu_option_groups, :schedules

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }
  let(:template) { Rails.root.join("public/plantillas/menu.csv") }

  def write_file(contents, extension: ".csv")
    Rails.root.join("tmp", "menu_test_#{SecureRandom.hex(4)}#{extension}")
         .tap { File.write(it, contents) }
  end

  # Sube la planilla y espera la vista previa, que es donde empieza lo que se
  # quiere probar.
  def upload(path)
    attach_file("file", path, make_visible: true)
    click_on "Subir archivo"
    expect(page).to have_content("Resumen")
  end

  # Cada plato de la vista previa es una tarjeta, y varias traen los mismos
  # botones: hay que entrar a la del plato para no tocar la de al lado.
  def card(name) = find("div.rounded-xl", text: name)

  before { sign_in provider_user, role: :provider }

  it "se entra desde Publicar menú y se descarga la plantilla" do
    visit_hydrated schedules_path

    click_on "Importar platos"

    expect(page).to have_current_path(provider_menu_import_path)
    expect(page).to have_content("Descargá la plantilla")
    expect(page).to have_link("Descargar plantilla", href: "/plantillas/menu.xlsx")
  end

  it "corrige la fila con error en la misma pantalla e importa el resto" do
    csv = write_file(<<~CSV)
      nombre,descripcion,precio
      Tarta de acelga,Casera y sana,290
      Budín de zanahoria,Con nueces,
    CSV

    visit_hydrated provider_menu_import_path
    upload(csv)

    # La fila mala se señala con el motivo y frena la importación; la otra
    # queda en pie.
    expect(page).to have_content("1 Nuevo")
    expect(page).to have_content("1 Error")
    expect(page).to have_content("El precio tiene que ser un número mayor que cero.")
    expect(page).to have_button("Importar platos", disabled: true)

    within(card("Budín de zanahoria")) { click_on "Editar" }

    expect(page).to have_content("Editar plato")
    find("#price").set("240")
    click_on "Modificar"

    expect(page).to have_content("2 Nuevos")
    expect(page).to have_button("Importar platos", disabled: false)

    initial_count = provider.menus.saved.count
    click_on "Importar platos"
    expect(page).to have_content("¡Platos importados!")
    expect(provider.menus.saved.count).to eq(initial_count + 2)
    expect(provider.menus.saved.find_by(name: "Budín de zanahoria").price).to eq(240)
  ensure
    FileUtils.rm_f(csv) if csv
  end

  it "quita del resumen la fila que el proveedor no quiere importar" do
    csv = write_file(<<~CSV)
      nombre,descripcion,precio
      Tarta de acelga,Casera y sana,290
      Budín de zanahoria,Con nueces,
    CSV

    visit_hydrated provider_menu_import_path
    upload(csv)

    within(card("Budín de zanahoria")) { click_on "Quitar" }

    expect(page).to have_no_content("Budín de zanahoria")
    expect(page).to have_button("Importar platos", disabled: false)

    initial_count = provider.menus.saved.count
    click_on "Importar platos"
    expect(page).to have_content("¡Platos importados!")
    expect(provider.menus.saved.count).to eq(initial_count + 1)
  ensure
    FileUtils.rm_f(csv) if csv
  end

  it "no importa un plato cuyo nombre ya existe a menos que el proveedor lo diga" do
    visit_hydrated provider_menu_import_path
    upload(template)

    # La plantilla de ejemplo trae la Milanesa, que el proveedor ya tiene.
    expect(page).to have_content("2 Nuevos")
    expect(page).to have_content("1 Ya existe")
    expect(page).to have_content("Este plato no se importará a menos que elijas una de las siguientes acciones.")

    initial_count = provider.menus.saved.count
    click_on "Importar platos"
    expect(page).to have_content("¡Platos importados!")
    expect(provider.menus.saved.count).to eq(initial_count + 2)
    expect(provider.menus.where(name: "Milanesa con papas fritas").count).to eq(1)
    expect(provider.menus.saved.find_by(name: "Sorrentinos")).to be_present
    expect(provider.menus.saved.find_by(name: "Ensalada César")).to be_present
  end

  it "actualiza el plato existente cuando el proveedor elige Actualizar" do
    visit_hydrated provider_menu_import_path
    upload(template)

    within(card("Milanesa con papas fritas")) { click_on "Actualizar" }

    expect(page).to have_content("¿Actualizar el plato guardado?")
    click_on "Aplicar cambios"

    expect(page).to have_content("1 Actualizado")
    expect(page).to have_content("2 Nuevos")

    click_on "Importar platos"
    expect(page).to have_content("¡Platos importados!")

    expect(provider.menus.find_by(name: "Milanesa con papas fritas").price).to eq(320)
  end

  it "duplica el plato existente cuando el proveedor elige Duplicar" do
    visit_hydrated provider_menu_import_path
    upload(template)

    within(card("Milanesa con papas fritas")) { click_on "Duplicar" }

    expect(page).to have_content("3 Nuevos")

    expect {
      click_on "Importar platos"
      expect(page).to have_content("¡Platos importados!")
    }.to change { provider.menus.where(name: "Milanesa con papas fritas").count }.by(1)
  end

  it "cambia de estado entre Nuevo y Ya existe al editar el nombre del plato" do
    visit_hydrated provider_menu_import_path
    upload(template)

    # Editar un plato Nuevo ("Sorrentinos") y ponerle el nombre de uno guardado ("Milanesa con papas fritas")
    within(card("Sorrentinos")) { click_on "Editar" }
    expect(page).to have_content("Editar plato")
    find("#name").set("Milanesa con papas fritas")
    click_on "Modificar"

    expect(page).to have_content("1 Nuevo")
    expect(page).to have_content("2 Ya existen")

    # Editar un plato Ya existe ("Milanesa con papas fritas") y ponerle un nombre nuevo
    all("div.rounded-xl", text: "Milanesa con papas fritas").first.click_button("Editar")
    expect(page).to have_content("Editar plato")
    find("#name").set("Milanesa napolitana artesanal")
    click_on "Modificar"

    expect(page).to have_content("2 Nuevos")
    expect(page).to have_content("1 Ya existe")
  end

  it "deshabilita el botón de importar si solo hay platos que Ya existen y no se tomó acción" do
    csv = write_file(<<~CSV)
      nombre,descripcion,precio
      Milanesa con papas fritas,Con papas,320
    CSV

    visit_hydrated provider_menu_import_path
    upload(csv)

    expect(page).to have_content("1 Ya existe")
    expect(page).to have_button("Importar platos", disabled: true)
  ensure
    FileUtils.rm_f(csv) if csv
  end

  it "avisa cuando el archivo no es una planilla" do
    pdf = write_file("no soy una planilla", extension: ".pdf")

    visit_hydrated provider_menu_import_path
    attach_file("file", pdf, make_visible: true)
    click_on "Subir archivo"

    expect(page).to have_content("El archivo tiene que ser .xlsx, .xls, .csv o .ods.")
    expect(page).to have_no_content("Resumen")
  ensure
    FileUtils.rm_f(pdf) if pdf
  end
end
