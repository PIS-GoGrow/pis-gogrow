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
    fill_in "notes", with: "Por favor enviar cubiertos extra"
    click_button "Guardar cambios"

    expect(page).to have_content("Pedido actualizado")
    expect(page).to have_current_path(order_path(order))
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
    click_button "Guardar cambios"

    expect(page).to have_content("Pedido actualizado")
    expect(page).to have_content("Edición desde mobile")
    expect(order.reload.notes).to eq("Edición desde mobile")
  end
end
