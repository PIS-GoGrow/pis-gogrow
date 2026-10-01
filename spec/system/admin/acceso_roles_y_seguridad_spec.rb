# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SYS-01: Acceso, roles y aislamiento de seguridad", type: :system do
  fixtures :users, :companies, :consumers, :admins, :providers, :menus, :schedules, :orders,
           :accounts, :order_accounts, :benefits, :benefit_configurations, :benefit_rules

  let(:consumer_user) { users(:one) }
  let(:admin_user) { users(:admin) }
  let(:provider_user_p1) { users(:provider_user) }
  let(:provider_user_p2) { users(:other_provider_user) }
  let(:dual_user) { users(:two) }

  after do
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end

  describe "Paso 1: Verificación de acceso e interfaz por rol" do
    it "1.1 Empleado: visualiza dashboard móvil con menú, subsidio y acceso a pedidos" do
      page.driver.browser.manage.window.resize_to(360, 800)
      sign_in consumer_user, role: :consumer
      visit dashboard_path

      expect(page).to have_content("Menú semanal")
      expect(page).to have_content("Tu consumo")
      expect(page).to have_content("viandas pedidas")
      expect(page).to have_link("Pedidos", href: orders_path)
    end

    it "1.2 RRHH: visualiza panel administrativo y gestión de subsidios en escritorio" do
      sign_in admin_user, role: :admin
      visit admin_benefit_configurations_path

      expect(page).to have_content("Subsidios")
      expect(page).to have_content("Subsidio Base")
    end

    it "1.3 Proveedor: visualiza portal de operaciones y pedidos del día en escritorio" do
      sign_in provider_user_p1, role: :provider
      visit provider_orders_path

      expect(page).to have_content("Pedidos")
      expect(page).to have_content(/operación diaria/i)
      expect(page).to have_content("Todos")
      expect(page).to have_content("Pendientes")
    end
  end

  describe "Paso 2: Aislamiento de rutas y rechazo de accesos cruzados" do
    context "con sesión activa de empleado" do
      before do
        sign_in consumer_user, role: :consumer
      end

      it "bloquea el acceso a rutas administrativas de RRHH" do
        visit admin_benefit_configurations_path

        expect(page).to have_no_current_path(admin_benefit_configurations_path)
        expect(page).to have_content("No tenés permiso para acceder a este recurso.")
      end

      it "bloquea el acceso a rutas de gestión de proveedor" do
        visit provider_orders_path

        expect(page).to have_no_current_path(provider_orders_path)
        expect(page).to have_content("No tenés permiso para acceder a este recurso.")
      end
    end

    context "con sesión activa de proveedor" do
      before do
        sign_in provider_user_p1, role: :provider
      end

      it "bloquea el acceso a rutas de empleado" do
        visit dashboard_path

        expect(page).to have_no_current_path(dashboard_path)
        expect(page).to have_content("No tenés permiso para acceder a este recurso.")
      end

      it "bloquea el acceso a rutas de RRHH" do
        visit admin_benefit_configurations_path

        expect(page).to have_no_current_path(admin_benefit_configurations_path)
        expect(page).to have_content("No tenés permiso para acceder a este recurso.")
      end
    end

    context "sin sesión activa (usuario no autenticado)" do
      it "redirige al inicio de sesión con mensaje informativo" do
        visit dashboard_path
        expect(page).to have_current_path(sign_in_path)
        expect(page).to have_content("Tenés que iniciar sesión para acceder a este recurso.")

        visit admin_benefit_configurations_path
        expect(page).to have_current_path(sign_in_path)

        visit provider_orders_path
        expect(page).to have_current_path(sign_in_path)
      end
    end
  end

  describe "Paso 3: Verificación de cuenta dual (Empleado + RRHH)" do
    before do
      Consumer.create!(user: dual_user, company: companies(:gogrow), address: "Av. 18 de Julio 1234")
      Admin.create!(user: dual_user, company: companies(:gogrow))
      dual_user.sync_roles!
    end

    it "mantiene navegación, permisos e independencia de sesión por rol" do
      # Acceso como Empleado
      sign_in dual_user, role: :consumer
      visit dashboard_path

      expect(page).to have_content("Menú semanal")
      expect(page).to have_content("Tu consumo")

      # Intento de entrar a RRHH con sesión de Empleado es rechazado
      visit admin_benefit_configurations_path
      expect(page).to have_content("No tenés permiso para acceder a este recurso.")

      sign_out

      # Acceso como RRHH
      sign_in dual_user, role: :admin
      visit admin_benefit_configurations_path

      expect(page).to have_content("Subsidios")
      expect(page).to have_content("Subsidio Base")

      # Intento de entrar a Empleado con sesión de RRHH es rechazado
      visit dashboard_path
      expect(page).to have_content("No tenés permiso para acceder a este recurso.")
    end
  end

  describe "Paso 4: Protección de recursos ajenos entre proveedores" do
    let(:sorrentinos) { menus(:sorrentinos) }
    let(:schedule_p2) { schedules(:sorrentinos_today) }
    let!(:order_p2) do
      Order.create!(
        consumer: consumers(:one),
        schedule: schedule_p2,
        status: :pending,
        amount: 1,
        price: 320,
        discounted_price: 160,
        delivery_method: :office,
        address: "Oficina"
      )
    end

    before do
      sign_in provider_user_p1, role: :provider
    end

    it "rechaza el acceso por URL directa a pedidos pertenecientes a otro proveedor" do
      visit provider_order_path(order_p2)

      expect(page).to have_no_content("Sorrentinos artesanales")
      expect {
        provider_user_p1.provider.orders.find(order_p2.id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "rechaza el acceso a cobros y cuentas pertenecientes a otro proveedor" do
      account_p2 = accounts(:one_endulzate_current)

      visit provider_collection_path(account_p2)

      expect(page).to have_no_content("500,00")
      expect {
        provider_user_p1.provider.accounts.find(account_p2.id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
