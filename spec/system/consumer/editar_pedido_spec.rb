# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Modificar un pedido desde la pantalla del plato", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules, :orders, :menu_option_groups

  let(:consumer) { consumers(:one) }
  let(:user) { users(:one) }
  let(:sorrentinos) { menus(:sorrentinos) }
  let(:salsa) { menu_option_groups(:salsa_sorrentinos) }
  let(:relleno) { menu_option_groups(:relleno_sorrentinos) }
  let!(:queso) do
    sorrentinos.option_groups.create!(
      name: "Queso rallado",
      options: [ "Parmesano", "Reggianito", "Sin queso" ],
      limit: 1,
      required: true
    )
  end

  let!(:schedule) do
    Schedule.create!(
      menu: sorrentinos,
      date: Date.current + 2.days,
      amount: 10
    )
  end

  let!(:order) do
    Order.create!(
      consumer: consumer,
      schedule: schedule,
      amount: 1,
      price: 320,
      discounted_price: 320,
      address: companies(:gogrow).address,
      delivery_method: :office,
      notes: "Nota inicial del pedido",
      selected_options: [
        { group_id: salsa.id, name: salsa.name, values: [ "Filetto" ] },
        { group_id: relleno.id, name: relleno.name, values: [ "Ricota y nuez" ] },
        { group_id: queso.id, name: queso.name, values: [ "Parmesano" ] }
      ]
    )
  end

  before do
    sorrentinos.update!(description: "Deliciosos sorrentinos artesanales rellenos de los ingredientes más frescos, acompañados de salsa casera y queso rallado de primera calidad para una experiencia gastronómica inigualable en el almuerzo corporativo.")
    sign_in user, role: :consumer
  end

  it "abre la misma pantalla que al pedir, con lo elegido cargado, y guarda los cambios" do
    visit_hydrated order_path(order)

    click_link "Editar"

    expect(page).to have_current_path(edit_order_path(order))
    expect(page).to have_content("Elegí tu/s salsa")
    expect(page).to have_content("Elegí tu/s relleno")
    expect(page).to have_content("Elegí tu/s queso rallado")
    expect(page).to have_field("notes", with: "Nota inicial del pedido")

    find("label", text: "Bolognesa").click
    # Capybara escribe por JS (sin disparar "input") los textos de más de 30
    # caracteres, y el textarea controlado por React descarta ese tramo.
    fill_in "notes", with: "Por favor enviar cubiertos extra", fill_options: { rapid: false }
    click_button "Modificar"

    confirm_order_modified
    visit_hydrated order_path(order)
    expect(page).to have_content("Bolognesa")
    expect(page).to have_content("Por favor enviar cubiertos extra")

    order.reload
    expect(order.notes).to eq("Por favor enviar cubiertos extra")
    salsa_selection = order.selected_options.find { |opt| opt["group_id"] == salsa.id }
    expect(salsa_selection["values"]).to eq([ "Bolognesa" ])
  end

  it "deja guardar los cambios en un viewport mobile" do
    page.current_window.resize_to(375, 667)

    visit_hydrated edit_order_path(order)

    fill_in "notes", with: "Edición desde mobile"
    click_button "Modificar"

    confirm_order_modified
    visit_hydrated order_path(order)
    expect(page).to have_content("Edición desde mobile")
    expect(order.reload.notes).to eq("Edición desde mobile")
  end

  it "mantiene el monto a pagar en la barra fija al editar en mobile" do
    page.current_window.resize_to(375, 667)

    visit_hydrated edit_order_path(order)

    total = find("span", text: "Monto a pagar")
    bar = total.find(:xpath, "ancestor::div[contains(@class, 'fixed')]")
    expect(bar).to have_button("Modificar")
    expect(page).to have_no_css("div.fixed", text: "Precio vianda")

    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
    viewport_height = page.evaluate_script("window.innerHeight")
    top = page.evaluate_script("arguments[0].getBoundingClientRect().top", total.native)
    bottom = page.evaluate_script("arguments[0].getBoundingClientRect().bottom", total.native)

    expect(top).to be >= 0
    expect(bottom).to be <= viewport_height
  end
end
