# frozen_string_literal: true

require "rails_helper"

# Historia IBP-045: "Como PROVEEDOR, quiero publicar el menú en un día específico
# para organizar la oferta con anticipación." Con IBP-003 (consultar el menú por
# fecha) e IBP-004 (información del plato) del lado del empleado: lo publicado
# tiene que aparecer solo en su fecha y sin mezclarse con otro proveedor.
#
# Fuera del rango permitido (más allá del viernes de la semana siguiente) y la
# publicación de un plato ajeno no se pueden provocar desde la pantalla: la
# guarda está en el server y la cubre spec/requests/schedules_spec.rb.
RSpec.describe "Publicar el menú de un día" do
  fixtures :users, :providers, :consumers, :companies

  let(:p1) { providers(:tuviandita) }
  let(:p1_user) { users(:provider_user) }
  let(:p2) { providers(:endulzate) }
  let(:p2_user) { users(:other_provider_user) }
  let(:e1_user) { users(:one) }

  let(:monday) { Date.current.beginning_of_week(:monday) }
  let(:day_d) { monday + 1 }
  let(:other_day) { monday + 2 }

  let!(:p1_milanesa) { p1.menus.create!(name: "Milanesa al pan", description: "Con papas", price: 300) }
  let!(:p1_wok) { p1.menus.create!(name: "Wok de vegetales", description: "Salteado", price: 290) }
  let!(:p2_torta) { p2.menus.create!(name: "Torta de ricota", description: "Postre casero", price: 250) }

  # Lunes futuro: la semana queda completa y por delante del reloj del browser,
  # que es con el que el menú del empleado decide si un día ya pasó.
  around do |example|
    travel_to(Date.current.next_occurring(:monday).change(hour: 10)) { example.run }
  end

  before do
    Order.destroy_all
    Schedule.delete_all
  end

  def open_publication_day(date, week_start: date.beginning_of_week(:monday))
    visit schedules_path(week_start: week_start.to_s)
    find("button", text: /\b#{date.day}\b/).click
  end

  def pick_dish(dish, amount)
    find("p", text: dish.name, exact_text: true).click
    fill_in "amount-#{dish.id}", with: amount.to_s
  end

  def pick_menu_day(date)
    within("[role=radiogroup]") { find("[role=radio]", text: /\b#{date.day}\b/).click }
  end

  def only_provider(name)
    find("button[aria-label='Filtrar por proveedores']").click
    unless page.has_selector?("[role=dialog]", wait: 2)
      find("button[aria-label='Filtrar por proveedores']").click
    end
    within("[role=dialog]") do
      find("label", text: name, exact_text: true).click
      click_button "Aplicar"
    end
  end

  # Pasos: publicar oferta para D, consultar como E1 la fecha D, otra fecha y el
  # menú de P2. Esperado: E1 ve los platos y datos del menú publicado para D, sin
  # mezclar fechas ni proveedores.
  it "muestra a E1 lo publicado para D, sin mezclar fechas ni proveedores" do
    p2_torta.schedules.create!(date: day_d, amount: 4)
    p1_wok.schedules.create!(date: other_day, amount: 4)

    sign_in p1_user, role: :provider
    open_publication_day(day_d)
    expect(page).to have_content("Sin publicar")
    pick_dish(p1_milanesa, 5)
    click_button "Publicar menú"
    expect(page).to have_content("Publicado")
    expect(p1_milanesa.schedules.sole).to have_attributes(date: day_d, amount: 5)
    sign_out

    sign_in e1_user, role: :consumer
    visit dashboard_path
    pick_menu_day(day_d)
    expect(page).to have_content("Milanesa al pan")
    expect(page).to have_content("$300")
    expect(page).to have_content("Con papas")
    expect(page).to have_content("Torta de ricota")
    expect(page).to have_no_content("Wok de vegetales")

    pick_menu_day(other_day)
    expect(page).to have_content("Wok de vegetales")
    expect(page).to have_no_content("Milanesa al pan")
    expect(page).to have_no_content("Torta de ricota")

    pick_menu_day(day_d)
    only_provider(p2_user.name)
    expect(page).to have_content("Proveedores: #{p2_user.name}")
    expect(page).to have_content("Torta de ricota")
    expect(page).to have_content("Postre casero")
    expect(page).to have_no_content("Milanesa al pan")
  end

  it "no muestra nada a los empleados mientras el plato está elegido pero sin publicar" do
    sign_in p1_user, role: :provider
    open_publication_day(day_d)
    pick_dish(p1_milanesa, 5)
    sign_out

    sign_in e1_user, role: :consumer
    visit dashboard_path
    pick_menu_day(day_d)

    expect(page).to have_content("Menú no disponible")
    expect(page).to have_no_content("Milanesa al pan")
    expect(Schedule.count).to eq(0)
  end

  it "sigue publicado al recargar y al volver a entrar" do
    sign_in p1_user, role: :provider
    open_publication_day(day_d)
    pick_dish(p1_milanesa, 5)
    click_button "Publicar menú"
    expect(page).to have_content("Publicado")

    refresh
    find("button", text: /\b#{day_d.day}\b/).click
    expect(page).to have_content("Publicado")
    expect(page).to have_content("Milanesa al pan")
    sign_out

    sign_in p1_user, role: :provider
    open_publication_day(day_d)
    expect(page).to have_content("Publicado")
    expect(page).to have_content("Stock: 5")
  end

  describe "criterio 3: fechas pasadas y duplicados" do
    before { sign_in p1_user, role: :provider }

    it "no ofrece publicar en un día que ya pasó" do
      open_publication_day(monday - 6, week_start: monday - 7)

      expect(page).to have_content("Fuera de rango de publicación")
      expect(page).to have_content("No se puede publicar en esta fecha.")
      expect(page).to have_no_button("Publicar menú")
    end

    it "no ofrece publicar otra vez un día ya publicado, solo editarlo" do
      p1_milanesa.schedules.create!(date: day_d, amount: 5)

      open_publication_day(day_d)

      expect(page).to have_content("Publicado")
      expect(page).to have_no_button("Publicar menú")
      expect(page).to have_button("Editar menú")
    end

    it "no publica sin ningún plato elegido" do
      open_publication_day(day_d)

      expect(page).to have_button("Publicar menú", disabled: true)
    end

    {
      "sin stock" => "",
      "con stock cero" => "0",
      "con stock negativo" => "-3",
      "con stock no entero" => "2.5"
    }.each do |label, amount|
      it "no publica un plato #{label}" do
        open_publication_day(day_d)
        pick_dish(p1_milanesa, amount)
        click_button "Publicar menú"

        expect(page).to have_css("p.text-destructive")
        expect(page).to have_content("Sin publicar")
        expect(Schedule.count).to eq(0)
      end
    end

    it "publica con el stock mínimo de una unidad" do
      open_publication_day(day_d)
      pick_dish(p1_milanesa, 1)
      click_button "Publicar menú"

      expect(page).to have_content("Publicado")
      expect(p1_milanesa.schedules.sole.amount).to eq(1)
    end
  end

  describe "permisos" do
    it "P2 no ve los platos de P1 para publicar" do
      sign_in p2_user, role: :provider
      open_publication_day(day_d)

      expect(page).to have_content("Torta de ricota")
      expect(page).to have_no_content("Milanesa al pan")
    end

    it "un empleado no llega a la pantalla de publicación" do
      sign_in e1_user, role: :consumer
      visit schedules_path

      expect(page).to have_no_current_path(schedules_path)
      expect(page).to have_no_button("Publicar menú")
    end
  end
end
