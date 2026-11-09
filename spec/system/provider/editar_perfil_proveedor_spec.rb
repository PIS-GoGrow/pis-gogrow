# frozen_string_literal: true

require "rails_helper"

# Historia IBP-048: "Como PROVEEDOR, quiero consultar y configurar los datos y
# preferencias de notificación de mi perfil para gestionar mi cuenta."
#
# Criterio 1 (nombre) y criterio 3 (validación y persistencia) sobre la pantalla
# /settings/profile, la misma donde vive el switch de entregas a domicilio
# (IBP-068, cubierto en configurar_modalidad_de_entrega_spec.rb). Acá se ejercita
# sólo nombre y teléfono, que es lo que este cambio agregó a esa pantalla.
#
# El correo electrónico se edita en otra pantalla (/configuracion/correo-electronico) y tiene su
# propio spec: editar_correo_proveedor_spec.rb. La foto no es editable todavía:
# ver el TODO(integración) en consultar_cuenta_proveedor_spec.rb.
RSpec.describe "Editar los datos personales del proveedor" do
  fixtures :users, :providers, :consumers, :companies, :admins

  let(:provider_user) { users(:provider_user) }

  it "guarda nombre y teléfono y persisten al volver a iniciar sesión" do
    sign_in provider_user, role: :provider
    visit settings_profile_path

    fill_in "name", with: "Viandas del Sur"
    fill_in "phone", with: "+598 99 123-456"
    click_on "Guardar"

    expect(page).to have_content("Tu perfil fue actualizado")
    expect(provider_user.reload).to have_attributes(name: "Viandas del Sur", phone: "+59899123456")

    sign_out
    sign_in provider_user, role: :provider
    visit settings_profile_path

    expect(page).to have_field("name", with: "Viandas del Sur")
    expect(page).to have_field("phone", with: "+59899123456")
  end

  it "rechaza un teléfono inválido y no lo guarda" do
    sign_in provider_user, role: :provider
    visit settings_profile_path

    fill_in "phone", with: "llamame"
    click_on "Guardar"

    expect(page).to have_css("[data-slot=field-error]", text: "No es un celular válido. Si no es de Uruguay, escribilo con + y el código de país.")
    expect(provider_user.reload.phone).to be_nil
  end

  it "registra quién cambió el teléfono y los valores anterior y nuevo" do
    sign_in provider_user, role: :provider
    visit settings_profile_path

    fill_in "phone", with: "099123456"
    click_on "Guardar"

    expect(page).to have_content("Tu perfil fue actualizado")
    expect(provider_user.reload.audit_logs.sole).to have_attributes(
      user: provider_user,
      changeset: { "phone" => [ nil, "+59899123456" ] }
    )
  end

  it "no permite que un consumidor edite los datos del proveedor" do
    consumer = users(:one)
    sign_in consumer, role: :consumer
    visit settings_profile_path

    fill_in "name", with: "Consumidor Editado"
    click_on "Guardar"

    expect(page).to have_content("Tu perfil fue actualizado")
    expect(consumer.reload.name).to eq("Consumidor Editado")
    expect(provider_user.reload.name).to eq("Provider User")
  end
end
