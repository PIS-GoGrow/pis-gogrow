# frozen_string_literal: true

# Historia IBP-038 "Como RR.HH., quiero disponer de un registro de auditoría de
# todos los cambios realizados en los pedidos, para poder resolver cualquier
# disputa sobre si una comida fue solicitada o si corresponde cobrarla."
# Los roles sin acceso, la otra empresa, el filtro por fechas y el intento de
# PATCH/DELETE directo se cubren en spec/requests/admin/order_events_spec.rb.

require "rails_helper"

RSpec.describe "Auditoría de pedidos", type: :system do
  fixtures :users, :companies, :admins, :providers, :consumers, :menus, :menu_option_groups, :schedules, :orders

  let(:modified) { orders(:upcoming_pending_future) }
  let(:confirmed) { orders(:upcoming_pending_today) }

  before { page.current_window.resize_to(1400, 1400) }

  def row_for(field)
    find("tbody tr", text: field).all("td").map(&:text)
  end

  def clear_filters
    click_link "Limpiar"
    expect(page).to have_current_path(admin_order_events_path)
    expect(page).to have_content("PED-#{modified.id}").and have_content("PED-#{confirmed.id}")
  end

  def as(user, role)
    Current.session = users(user).sessions.create!(role:)
    yield
  ensure
    Current.reset
  end

  # CA1, CA2 y CA3: lo que el empleado y el proveedor hacen desde sus pantallas
  # le llega a RR. HH. con quién, con qué rol y los valores anterior y nuevo.
  it "muestra a RR. HH. lo que cambió cada rol, con los valores anterior y nuevo" do
    sign_in users(:one), role: :consumer
    visit_hydrated order_path(modified)
    click_button "Editar"
    within("[role=dialog]") do
      click_button "Agregar uno"
      click_button "Guardar cambios"
    end
    expect(page).to have_content("Pedido actualizado")

    sign_out
    sign_in users(:provider_user), role: :provider
    visit provider_orders_path
    within("[data-slot='card']", text: "PED-#{confirmed.id}") do
      click_button "Confirmar"
      expect(page).to have_content("Confirmado")
    end

    sign_out
    sign_in users(:admin), role: :admin
    visit_hydrated root_path
    click_link "Auditoría", match: :first

    expect(page).to have_content("Auditoría de pedidos")
    occurred_at, code, actor, role, action = row_for("Modificación")
    expect(occurred_at).to match(%r{\A\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}\z})
    expect(code).to include("PED-#{modified.id}", "Test User")
    expect([ actor, role, action ]).to eq([ "Test User", "Empleado", "Modificación" ])
    modified.reload
    expect(row_for("Cantidad").last(3)).to eq([ "Cantidad", "1", "2" ])
    expect(row_for("Precio de lista").last(3)).to eq([ "Precio de lista", Account.format_amount(300.5), Account.format_amount(modified.price) ])
    expect(row_for("Precio a cobrar").last(3)).to eq([ "Precio a cobrar", Account.format_amount(150.25), Account.format_amount(modified.discounted_price) ])

    confirmation = row_for("Confirmación")
    expect(confirmation[1]).to include("PED-#{confirmed.id}")
    expect(confirmation[2..]).to eq([ "Provider User", "Proveedor", "Confirmación", "Estado", "Pendiente", "Confirmado" ])
  end

  # CA4: cada filtro deja solo lo que coincide con él, desde la pantalla.
  it "filtra por acción, rol, actor y pedido desde la pantalla" do
    as(:one, :consumer) { modified.update!(notes: "Sin sal") }
    as(:provider_user, :provider) { confirmed.decide(:confirmed, by: users(:provider_user)) }
    sign_in users(:admin), role: :admin
    visit_hydrated admin_order_events_path
    without_animations

    find("#event_action").click
    page.document.find("[role=option]", text: "Confirmación", exact_text: true).click
    click_button "Filtrar"
    expect(page).to have_no_content("PED-#{modified.id}")
    expect(page).to have_content("PED-#{confirmed.id}")

    clear_filters
    find("#role").click
    page.document.find("[role=option]", text: "Empleado", exact_text: true).click
    click_button "Filtrar"
    expect(page).to have_no_content("PED-#{confirmed.id}")
    expect(page).to have_content("PED-#{modified.id}")

    clear_filters
    fill_in "actor", with: "provider"
    click_button "Filtrar"
    expect(page).to have_no_content("PED-#{modified.id}")
    expect(page).to have_content("PED-#{confirmed.id}")

    clear_filters
    fill_in "order_id", with: "PED-#{modified.id}"
    click_button "Filtrar"
    expect(page).to have_no_content("PED-#{confirmed.id}")
    expect(page).to have_content("PED-#{modified.id}")
  end

  # CA4: la pantalla no ofrece ninguna acción sobre un evento.
  it "no ofrece editar ni borrar eventos" do
    as(:one, :consumer) { modified.update!(notes: "Sin sal") }
    sign_in users(:admin), role: :admin
    visit_hydrated admin_order_events_path

    expect(page).to have_css("tbody tr", count: 1)
    expect(page).to have_no_css("tbody button, tbody a, tbody input")
  end

  it "permite volver a Cuenta con la flecha junto al título" do
    sign_in users(:admin), role: :admin
    visit_hydrated admin_order_events_path

    find("a[aria-label='Volver a Cuenta']").click
    expect(page).to have_current_path(admin_account_path)
  end
end
