# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Programar cierres de recepción de pedidos como proveedor", type: :system do
  fixtures :users, :providers, :menus, :schedules, :orders, :consumers, :companies

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }
  let(:monday) { Date.current.next_week(:monday) }
  let(:target_date) { monday + 2.days }

  before do
    provider.closures.destroy_all
    Schedule.where(date: monday..monday + 4.days).destroy_all
    sign_in provider_user, role: :provider
  end

  it "programa un cierre, no permite publicar para esa fecha y luego permite eliminarlo" do
    visit_hydrated provider_operational_settings_path

    expect(page).to have_content("Cierres programados")
    expect(page).to have_content("Días en los que no recibís pedidos.")

    click_button "Programar cierre"

    expect(page).to have_content("Seleccioná el rango de fechas y el motivo del cierre.")

    pick_date "#closure-range", target_date
    fill_in "closure-reason", with: "Mantenimiento del local"
    click_button "Guardar cambios"

    expect(page).to have_content("¡Cierre programado!")
    click_button "Listo"

    expect(page).to have_content("Mantenimiento del local")
    expect(provider.closures.reload.count).to eq(1)
    expect(provider.closures.last.reason).to eq("Mantenimiento del local")

    visit_hydrated schedules_path(week_start: monday.to_s)
    expect(page).to have_content("Menú de la semana")

    # Miércoles está cerrado: no es publicable
    find("button", text: /\b#{target_date.day}\b/).click
    expect(page).to have_content("No se publicó menú para este día.")
    expect(page).to have_no_link("Agregar platos")

    # Lunes está abierto: sí se puede publicar
    find("button", text: /\b#{monday.day}\b/).click
    expect(page).to have_content("No hay platos publicados para el #{DateFormat.long(monday, inline: true)} todavía")
    expect(page).to have_link("Agregar platos")

    visit_hydrated provider_operational_settings_path

    find("button[aria-label='Editar cierre Mantenimiento del local']").click
    expect(page).to have_field("closure-reason", with: "Mantenimiento del local")
    fill_in "closure-reason", with: "Vacaciones del personal"
    click_button "Guardar cambios"
    expect(page).to have_content("¡Cierre actualizado!")
    click_button "Listo"

    expect(page).to have_content("Vacaciones del personal")
    expect(provider.closures.reload.last.reason).to eq("Vacaciones del personal")

    find("button[aria-label='Eliminar cierre Vacaciones del personal']").click
    expect(page).to have_content("Cierre eliminado.")
    expect(page).to have_no_content("Vacaciones del personal")
    expect(provider.closures.count).to eq(0)
  end

  it "rechaza programar un cierre sin motivo" do
    visit_hydrated provider_operational_settings_path

    click_button "Programar cierre"
    pick_date "#closure-range", target_date
    fill_in "closure-reason", with: ""
    click_button "Guardar cambios"

    expect(page).to have_content("Ingresá el motivo del cierre.")
    expect(provider.closures.count).to eq(0)
  end
end
