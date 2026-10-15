# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Publicar menú para repetir todas las semanas", type: :system do
  fixtures :users, :providers, :menus, :schedules, :orders, :consumers, :companies

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }
  let(:milanesa) { menus(:milanesa) }

  before do
    sign_in provider_user, role: :provider
  end

  it "permite configurar un plato para repetir todas las semanas y persiste la agenda semanal sin errores" do
    visit edit_provider_menu_path(milanesa)

    expect(page).to have_field("name", with: milanesa.name)

    # Selecciona la opción 'Repetir todas las semanas' primero
    find("label", text: "Repetir todas las semanas").click

    # Selecciona lunes y miércoles en los botones de días de la semana
    find("button[aria-label='Lunes']").click
    find("button[aria-label='Miércoles']").click

    click_button "Modificar"

    # La hoja de confirmación debe mostrar el período a partir del cual rige
    expect(page).to have_content("¿Aplicar cambios desde esta fecha?")

    click_button "Aplicar cambios"

    # Verificación de pantalla de éxito
    expect(page).to have_content("¡Plato modificado!")

    # Verificación en la base de datos
    agenda = milanesa.reload.current_agenda
    expect(agenda).to be_present
    expect(agenda.weekdays).to include(1, 3)
    expect(agenda.amount).to be_nil

    # Al acceder a editar un día programado generado por la agenda, se mantiene el modo weekly
    future_schedule = Schedule.where(menu_id: milanesa.family_ids, date: Date.current..).first
    expect(future_schedule).to be_present

    visit edit_provider_menu_path(milanesa, schedule_id: future_schedule.id)

    expect(page).to have_field("name", with: milanesa.name)
    expect(page).to have_selector("#agenda-mode-weekly[data-state='checked']")
  end
end
