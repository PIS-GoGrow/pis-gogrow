# frozen_string_literal: true

# TODO(integración): falta implementar el envío real en WhatsappSenderJob (va en
# otro PR; hoy el POST a la API de WhatsApp está comentado, sin token ni teléfono
# configurable) antes de poder testear que el empleado efectivamente recibe el mensaje por
# WhatsApp (CA2/CA3). Hoy solo se prueba que el envío se encola o no, en
# spec/services/notifier_spec.rb. Historia 23 "Como EMPLEADO, quiero activar o
# desactivar las notificaciones por WhatsApp".

require "rails_helper"

RSpec.describe "Activar y desactivar notificaciones por WhatsApp", type: :system do
  fixtures :users, :companies, :consumers, :admins

  let(:employee) { users(:one) }
  let(:orders_title) { "Actualizaciones de pedidos" }
  let(:reminders_title) { "Recordatorios de pago del proveedor" }

  def row_for(title)
    find("h2", text: title).ancestor("div.border-b")
  end

  def switch_for(title)
    row_for(title).find("button[role='switch']")
  end

  def expect_switch(title, on:)
    expect(row_for(title)).to have_css("button[role='switch'][aria-checked='#{on}']")
  end

  it "muestra la sección con un interruptor por grupo configurable, apagado al principio" do
    sign_in employee, role: :consumer
    visit settings_profile_path
    click_link "Notificaciones"

    expect(page).to have_content("Configurá qué alertas querés recibir por WhatsApp")
    expect_switch(orders_title, on: false)
    expect(page).to have_no_content(reminders_title)
    expect(page).to have_no_content("Pagos a proveedores")
  end

  it "conserva lo elegido al recargar y al volver a ingresar" do
    sign_in employee, role: :consumer
    visit settings_notifications_path

    switch_for(orders_title).click
    expect(page).to have_content("Configuración actualizada")
    expect_switch(orders_title, on: true)

    visit settings_notifications_path
    expect_switch(orders_title, on: true)

    sign_out
    sign_in employee, role: :consumer
    visit settings_notifications_path
    expect_switch(orders_title, on: true)

    switch_for(orders_title).click
    expect_switch(orders_title, on: false)

    sign_out
    sign_in employee, role: :consumer
    visit settings_notifications_path
    expect_switch(orders_title, on: false)
  end

  it "lo que prende un empleado no cambia lo de otro" do
    sign_in employee, role: :consumer
    visit settings_notifications_path
    switch_for(orders_title).click
    expect(page).to have_content("Configuración actualizada")
    sign_out

    sign_in users(:other_consumer_user), role: :consumer
    visit settings_notifications_path
    expect_switch(orders_title, on: false)
  end

  it "al admin le muestra solo sus grupos, no los del empleado" do
    sign_in users(:admin), role: :admin
    visit settings_notifications_path

    expect(page).to have_content("Pagos a proveedores")
    expect(page).to have_no_content(orders_title)
    expect(page).to have_no_content(reminders_title)
  end
end
