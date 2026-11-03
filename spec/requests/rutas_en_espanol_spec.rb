# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Rutas en español, control de acceso y casos borde", type: :request do
  fixtures :users, :companies, :admins, :providers, :consumers, :menus, :schedules,
           :orders, :accounts, :order_accounts, :payments, :benefits, :benefit_configurations

  let(:consumer_user) { users(:one) }
  let(:admin_user) { users(:admin) }
  let(:provider_user) { users(:provider_user) }
  let(:company_account) { accounts(:gogrow_tuviandita_current) }

  def receipt_upload(content_type: "image/png", filename: "comprobante.png")
    Rack::Test::UploadedFile.new(
      Rails.root.join(content_type == "text/plain" ? "public/robots.txt" : "public/icon.png"),
      content_type,
      original_filename: filename
    )
  end

  describe "1. Resolución y renderizado de rutas en español" do
    it "GET /iniciar-sesion redirige al login de empleados" do
      get "/iniciar-sesion"

      expect(response).to redirect_to("/consumidor")
    end

    it "GET /menu-semanal redirige a /consumidor si no está autenticado" do
      get dashboard_path

      expect(response).to redirect_to(consumer_welcome_path)
    end

    it "GET /menu-semanal responde con éxito y entrega props para consumidor" do
      sign_in consumer_user, role: :consumer
      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(inertia).to render_component("consumer/dashboard/index")
      expect(request.path).to eq("/menu-semanal")
      expect(inertia.props[:benefit]).to be_present
      expect(inertia.props[:schedules]).to be_present
    end

    it "GET /rrhh/pagos resuelve en el path en español y entrega props para admin" do
      sign_in admin_user, role: :admin
      get admin_payments_path

      expect(response).to have_http_status(:ok)
      expect(inertia).to render_component("admin/payments/index")
      expect(request.path).to eq("/rrhh/pagos")
      expect(inertia.props[:accounts]).to be_present
    end

    it "GET /proveedor/inicio resuelve y entrega props para el proveedor" do
      sign_in provider_user, role: :provider
      get provider_dashboard_path

      expect(response).to have_http_status(:ok)
      expect(inertia).to render_component("provider/dashboard/index")
      expect(request.path).to eq("/proveedor/inicio")
    end
  end

  describe "2. Control de acceso por rol (RBAC)" do
    it "consumidor intentando acceder a /rrhh/pagos es redirigido a la raíz con alerta" do
      sign_in consumer_user, role: :consumer
      get admin_payments_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("No tenés permiso para acceder a este recurso.")
    end

    it "proveedor intentando acceder a /menu-semanal es redirigido a la raíz con alerta" do
      sign_in provider_user, role: :provider
      get dashboard_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("No tenés permiso para acceder a este recurso.")
    end

    it "empleado intentando acceder a /proveedor/inicio es redirigido a la raíz con alerta" do
      sign_in consumer_user, role: :consumer
      get provider_dashboard_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("No tenés permiso para acceder a este recurso.")
    end
  end

  describe "3. Bypass de interfaz y tipos de datos inesperados" do
    it "POST /rrhh/pagos con ID inexistente devuelve 404 not found" do
      sign_in admin_user, role: :admin
      post admin_payments_path, params: {
        payment: { account_id: 999_999, receipt: receipt_upload }
      }

      expect(response).to have_http_status(:not_found)
    end

    it "POST /rrhh/pagos con tipo de dato no numérico para account_id maneja el error con 404" do
      sign_in admin_user, role: :admin
      post admin_payments_path, params: {
        payment: { account_id: "invalido_string", receipt: receipt_upload }
      }

      expect(response).to have_http_status(:not_found)
    end

    it "POST /iniciar-sesion con payload malformado o credenciales erróneas redirige con 422 o alerta" do
      post sign_in_path, params: { email_address: "no_existe@gogrow.com", password: "bad" }

      expect(response).to have_http_status(:unprocessable_content).or have_http_status(:redirect)
    end
  end

  describe "4. Validación de 422 y de integridad en la base de datos" do
    it "POST /rrhh/pagos sin comprobante rechaza con 422 y preserva los errores de validación" do
      sign_in admin_user, role: :admin
      post admin_payments_path, params: { payment: { account_id: company_account.id } }

      expect(response).to redirect_to(admin_payments_path)
      follow_redirect!
      expect(inertia.props[:errors]).to be_present
      expect(inertia.props[:errors][:receipt]).to be_present
    end

    it "rechaza subir un segundo comprobante cuando ya existe uno en revisión sin duplicar registros" do
      sign_in admin_user, role: :admin

      # Primer comprobante válido
      post admin_payments_path, params: {
        payment: { account_id: company_account.id, receipt: receipt_upload }
      }
      expect(response).to redirect_to(admin_payments_path)

      # Intento de bypass de interfaz: segundo comprobante directo al endpoint
      expect {
        post admin_payments_path, params: {
          payment: { account_id: company_account.id, receipt: receipt_upload }
        }
      }.not_to change(Payment, :count)

      follow_redirect!
      expect(inertia.props[:errors]).to be_present
    end
  end
end
