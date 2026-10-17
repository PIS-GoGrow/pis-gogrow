# frozen_string_literal: true

# Historia IBP-031: "Como RRHH, quiero consultar / configurar los datos de mi
# perfil y preferencias de notificación para gestionar mi cuenta."
#
# Criterios: (1) RRHH puede consultar sus datos de perfil y las preferencias de
# notificación disponibles; (2) solo puede modificar los campos expresamente
# habilitados; (3) los datos se validan antes de guardarse y la nueva
# configuración persiste al volver a ingresar; (4) el sistema confirma el
# guardado o informa los errores sin perder los cambios ingresados.
#
# Los campos habilitados son nombre y teléfono (Settings::ProfilesController#user_params)
# y las suscripciones a los grupos de notificación de RRHH; el email es solo de
# consulta.

require "rails_helper"

RSpec.describe "Perfil y preferencias de notificación de RRHH", type: :system do
  fixtures :users, :companies, :admins, :consumers

  let(:admin_user) { users(:admin) }
  let(:hr_notification_titles) do
    [ "Pagos a proveedores", "Pagos pendientes", "Comprobantes rechazados", "Pagos parciales",
      "Facturas pendientes", "Cambios en subsidios", "Deudas de empleados" ]
  end
  let(:invoices_title) { "Facturas pendientes" }
  let(:invalid_phone_message) { User.new(phone: "x").tap(&:validate).errors[:phone].first }

  def open_profile(user = admin_user)
    sign_in user, role: :admin
    visit admin_account_path
    click_link "Perfil y Apariencia"
    click_link "Perfil"
    expect(page).to have_content("Información del perfil")
  end

  def save_profile(name: nil, phone: nil)
    fill_in "Nombre", with: name if name
    fill_in "Teléfono", with: phone if phone
    click_button "Guardar"
  end

  def row_for(title)
    find("h2", text: title).ancestor("div.border-b")
  end

  def expect_switch(title, on:)
    expect(row_for(title)).to have_css("button[role='switch'][aria-checked='#{on}']")
  end

  describe "consultar (CA1)" do
    it "llega a su cuenta desde el menú y ve su nombre y email" do
      sign_in admin_user, role: :admin
      visit admin_dashboard_path
      click_link "Cuenta", match: :first

      expect(page).to have_current_path(admin_account_path)
      expect(page).to have_content("Admin User")
      expect(page).to have_content("admin@example.com")
    end

    it "ve sus datos de perfil cargados" do
      admin_user.update!(phone: "099123456")
      open_profile

      expect(page).to have_field("Nombre", with: "Admin User")
      expect(page).to have_field("Teléfono", with: "099123456")
      expect(page).to have_field("Correo electrónico", with: "admin@example.com")
    end

    it "ve todas las preferencias de notificación de RRHH, apagadas al principio, y ninguna de otro rol" do
      sign_in admin_user, role: :admin
      visit admin_account_path
      click_link "Notificaciones"

      expect(page).to have_content("Preferencias de RRHH")
      hr_notification_titles.each { expect_switch(it, on: false) }
      expect(page).to have_no_content("Actualizaciones de pedidos")
      expect(page).to have_no_content("Recordatorios de pago de Recursos Humanos")
    end
  end

  describe "campos habilitados (CA2)" do
    it "el email es solo de consulta y no hay opción de eliminar la cuenta" do
      open_profile

      expect(page).to have_field("Correo electrónico", with: "admin@example.com", readonly: true)
      expect(page).to have_content("Este dato es solo de consulta y no se puede modificar.")
      expect(page).to have_no_button("Eliminar cuenta")
    end
  end

  describe "validar y persistir (CA3) con confirmación (CA4)" do
    it "guarda nombre y teléfono, confirma, y los conserva al recargar y al volver a ingresar" do
      open_profile

      save_profile(name: "RRHH Editado", phone: "+598 99 123-456")

      expect(page).to have_content("Tu perfil fue actualizado")
      expect(admin_user.reload).to have_attributes(name: "RRHH Editado", phone: "+59899123456")

      visit current_path
      expect(page).to have_field("Nombre", with: "RRHH Editado")

      sign_out
      open_profile
      expect(page).to have_field("Nombre", with: "RRHH Editado")
      expect(page).to have_field("Teléfono", with: "+59899123456")
      expect(page).to have_field("Correo electrónico", with: "admin@example.com")
    end

    it "acepta los largos límite del teléfono (8 y 15 dígitos)" do
      open_profile

      save_profile(phone: "12345678")
      expect(page).to have_content("Tu perfil fue actualizado")
      expect(admin_user.reload.phone).to eq("12345678")

      save_profile(phone: "123456789012345")
      expect(page).to have_field("Teléfono", with: "123456789012345")
      expect(admin_user.reload.phone).to eq("123456789012345")
    end

    [ "1234567", "1234567890123456", "llamame" ].each do |phone|
      it "rechaza el teléfono #{phone.inspect} sin perder lo ingresado ni guardar nada" do
        open_profile

        save_profile(name: "RRHH Editado", phone:)

        expect(page).to have_content(invalid_phone_message)
        expect(page).to have_field("Nombre", with: "RRHH Editado")
        expect(page).to have_field("Teléfono", with: phone)
        expect(admin_user.reload).to have_attributes(name: "Admin User", phone: nil)
      end
    end

    it "rechaza un nombre con solo espacios sin perder el teléfono ingresado" do
      open_profile

      save_profile(name: "   ", phone: "099123456")

      expect(page).to have_content(User.new.tap(&:validate).errors[:name].first)
      expect(page).to have_field("Teléfono", with: "099123456")
      expect(admin_user.reload).to have_attributes(name: "Admin User", phone: nil)
    end

    it "una preferencia de notificación se confirma y persiste al volver a ingresar" do
      sign_in admin_user, role: :admin
      visit settings_notifications_path

      row_for(invoices_title).find("button[role='switch']").click
      expect(page).to have_content("Configuración actualizada")
      expect_switch(invoices_title, on: true)

      sign_out
      sign_in admin_user, role: :admin
      visit settings_notifications_path
      expect_switch(invoices_title, on: true)
      (hr_notification_titles - [ invoices_title ]).each { expect_switch(it, on: false) }

      row_for(invoices_title).find("button[role='switch']").click
      expect(page).to have_content("Configuración actualizada")
      expect_switch(invoices_title, on: false)

      visit settings_notifications_path
      expect_switch(invoices_title, on: false)
    end
  end

  describe "permisos y privacidad" do
    it "sin sesión no entra a la cuenta de RRHH" do
      visit admin_account_path

      expect(page).to have_current_path(sign_in_path)
    end

    it "un empleado no entra a la cuenta ni a las preferencias de RRHH aunque escriba la URL" do
      sign_in users(:one), role: :consumer

      [ admin_account_path, admin_preferences_path ].each do |path|
        visit path
        expect(page).to have_content(I18n.t("flash.no_permission"))
        expect(page).to have_no_current_path(path)
        expect(page).to have_no_content("Perfil y Apariencia")
      end
    end

    it "lo que configura un RRHH no cambia el perfil ni las preferencias de otro RRHH" do
      other_admin = User.create!(name: "Otra RRHH", email: "otra.rrhh@example.com", password: "x" * 12)
      Admin.create!(user: other_admin, company: companies(:gogrow))

      open_profile
      save_profile(name: "RRHH Editado")
      expect(page).to have_content("Tu perfil fue actualizado")
      visit settings_notifications_path
      row_for(invoices_title).find("button[role='switch']").click
      expect(page).to have_content("Configuración actualizada")
      sign_out

      open_profile(other_admin)
      expect(page).to have_field("Nombre", with: "Otra RRHH")
      visit settings_notifications_path
      expect_switch(invoices_title, on: false)
    end
  end
end
