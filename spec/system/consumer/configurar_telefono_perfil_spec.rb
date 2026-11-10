# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Configuración de teléfono de WhatsApp en perfil del consumidor", type: :system do
  fixtures :users, :companies, :consumers

  let(:consumer_user) { users(:one) }

  before do
    consumer_user.update_column(:phone, nil)
  end

  it "permite ingresar un celular uruguayo sin código de país y lo normaliza a formato internacional" do
    sign_in consumer_user, role: :consumer
    visit settings_profile_path

    expect(page).to have_content("Información del perfil")

    fill_in "Teléfono", with: "099 123 456"
    click_button "Guardar"

    expect(page).to have_content("Tu perfil fue actualizado")
    expect(consumer_user.reload.phone).to eq("+59899123456")

    visit settings_profile_path
    expect(find_field("Teléfono").value).to eq("+59899123456")
  end

  it "rechaza números fijos y texto inválido mostrando el mensaje de validación" do
    sign_in consumer_user, role: :consumer
    visit settings_profile_path

    # Teléfono fijo uruguayo
    fill_in "Teléfono", with: "2900 1234"
    click_button "Guardar"

    expect(page).to have_content("No es un celular válido. Si no es de Uruguay, escribilo con + y el código de país.")
    expect(consumer_user.reload.phone).to be_nil

    # Texto inválido
    fill_in "Teléfono", with: "llamame"
    click_button "Guardar"

    expect(page).to have_content("No es un celular válido. Si no es de Uruguay, escribilo con + y el código de país.")
    expect(consumer_user.reload.phone).to be_nil
  end

  it "persiste el número válido entre recargas de página y sesiones" do
    sign_in consumer_user, role: :consumer
    visit settings_profile_path

    fill_in "Teléfono", with: "+54 9 11 2345-6789"
    click_button "Guardar"

    expect(page).to have_content("Tu perfil fue actualizado")
    expect(consumer_user.reload.phone).to eq("+5491123456789")

    # Recarga de página
    visit settings_profile_path
    expect(find_field("Teléfono").value).to eq("+5491123456789")

    # Limpiar teléfono
    fill_in "Teléfono", with: ""
    click_button "Guardar"

    expect(page).to have_content("Tu perfil fue actualizado")
    expect(consumer_user.reload.phone).to be_nil
  end
end
