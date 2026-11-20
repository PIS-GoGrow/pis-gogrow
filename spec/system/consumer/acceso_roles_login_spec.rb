# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Acceso y login según rol de pantalla de entrada", type: :system do
  fixtures :users, :consumers, :admins, :companies

  around do |example|
    original = ENV["DEV_LOGIN_ENABLED"]
    ENV["DEV_LOGIN_ENABLED"] = "true"
    example.run
  ensure
    ENV["DEV_LOGIN_ENABLED"] = original
  end

  let(:password) { "Secret1*3*5*" }

  describe "Redirecciones de rutas de acceso" do
    it "redirige la raíz / a /consumidor" do
      visit root_path

      expect(page).to have_current_path(consumer_welcome_path)
    end

    it "redirige /iniciar-sesion a /consumidor" do
      visit "/iniciar-sesion"

      expect(page).to have_current_path(consumer_welcome_path)
    end
  end

  describe "Inicio de sesión con cuenta de doble rol (Empleado y RRHH)" do
    before do
      Admin.create!(user: users(:one), company: companies(:gogrow))
    end

    it "ingresa directamente al panel de consumidor cuando inicia desde /consumidor" do
      visit_hydrated consumer_welcome_path

      fill_in "email", with: users(:one).email
      fill_in "password", with: password
      click_button "Ingresar"

      expect(page).to have_current_path(dashboard_path)
    end

    it "ingresa directamente al panel de RRHH cuando inicia desde /rrhh" do
      visit_hydrated admin_welcome_path

      fill_in "email", with: users(:one).email
      fill_in "password", with: password
      click_button "Ingresar"

      expect(page).to have_current_path(admin_dashboard_path)
    end
  end

  describe "Restricciones de rol según pantalla de entrada" do
    it "rechaza a una cuenta de solo empleado que intenta ingresar por /rrhh y la mantiene en /rrhh" do
      visit_hydrated admin_welcome_path

      fill_in "email", with: users(:one).email
      fill_in "password", with: password
      click_button "Ingresar"

      expect(page).to have_current_path(admin_welcome_path)
      expect(page).to have_content(I18n.t("flash.role_not_available"))
    end

    it "rechaza a una cuenta de solo empleado que intenta ingresar por /proveedor y la mantiene en /proveedor" do
      visit_hydrated provider_home_path

      fill_in "email", with: users(:one).email
      fill_in "password", with: password
      click_button "Ingresar"

      expect(page).to have_current_path(provider_home_path)
      expect(page).to have_content(I18n.t("flash.role_not_available"))
    end

    it "rechaza credenciales incorrectas en /rrhh y mantiene al usuario en /rrhh" do
      visit_hydrated admin_welcome_path

      fill_in "email", with: users(:one).email
      fill_in "password", with: "clave-erronea"
      click_button "Ingresar"

      expect(page).to have_current_path(admin_welcome_path)
      expect(page).to have_content(I18n.t("flash.incorrect_credentials"))
    end
  end

  describe "Inicio de sesión con Google OAuth y manejo de UID" do
    let(:user) { users(:one) }

    before do
      user.update!(email: "e2e-consumer@gmail.com", google_uid: nil, avatar_url: nil)
    end

    after do
      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end

    it "asigna google_uid y avatar_url en el primer login y accede al panel" do
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "google-uid-sys-123",
        info: OmniAuth::AuthHash::InfoHash.new(
          email: user.email,
          name: user.name,
          image: "https://example.com/avatar-sys.png"
        )
      )

      visit_hydrated consumer_welcome_path
      click_button "Iniciar sesión con Google"

      expect(page).to have_current_path(dashboard_path)
      user.reload
      expect(user.google_uid).to eq("google-uid-sys-123")
      expect(user.avatar_url).to eq("https://example.com/avatar-sys.png")
    end

    it "muestra alerta de error cuando el google_uid no coincide con el de la cuenta" do
      user.update!(google_uid: "uid-original-guardado")

      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "uid-discrepante-456",
        info: OmniAuth::AuthHash::InfoHash.new(
          email: user.email,
          name: user.name,
          image: "https://example.com/avatar-sys.png"
        )
      )

      visit_hydrated consumer_welcome_path
      click_button "Iniciar sesión con Google"

      expect(page).to have_current_path(consumer_welcome_path)
      expect(page).to have_content(I18n.t("flash.google_uid_mismatch"))
    end
  end
end
