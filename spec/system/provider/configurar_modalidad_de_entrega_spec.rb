# frozen_string_literal: true

require "rails_helper"

# Historia IBP-068: "Como PROVEEDOR, quiero indicar si realizo entregas a
# domicilio o únicamente a la oficina de GoGrow, para que los empleados solo
# puedan elegir modalidades que puedo cumplir."
#
# La configuración vive en Cuenta > Entregas dentro del flujo del proveedor.
# El empleado no tiene pantalla propia para esto: su mitad de la historia
# (elegir entre las modalidades habilitadas) se cubre en
# consumer/elegir_modalidad_de_entrega_spec.rb.
#
# TODO(integración): falta un control para desactivar la entrega en la oficina
# antes de poder testear el criterio 1 completo ("habilitar la oficina, el
# domicilio o ambas"). Hoy el modelo tiene un único booleano, home_delivery, así
# que las tres combinaciones que pide el criterio se reducen a dos: solo
# oficina (home_delivery=false) y ambas (home_delivery=true). No existe forma de
# tener "solo domicilio". Historia, criterio 1.
#
# TODO(integración): falta la validación que impide dejar al proveedor sin
# ninguna modalidad antes de poder testear el criterio 4 ("al menos una
# modalidad debe permanecer habilitada mientras el proveedor tenga menús
# publicados"). Hoy el criterio no puede violarse porque el único booleano
# controlable es el del domicilio y la oficina está siempre habilitada, así que
# no hay caso negativo que provocar: no hay un estado "ninguna modalidad
# habilitada" que alcanzar. La parte que sí se puede comprobar es que un
# proveedor con menús publicados puede desactivar el domicilio sin que sus
# publicaciones se caigan, y eso se asserta más abajo. Historia, criterio 4.
RSpec.describe "Configurar la modalidad de entrega como proveedor" do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules, :orders

  let(:provider) { providers(:tuviandita) }

  def open_deliveries
    visit provider_account_path
    click_link I18n.t("pages.provider_accounts.show.deliveries")
    expect(page).to have_current_path(provider_deliveries_path)
  end

  def home_delivery_checked?
    find("#delivery-home", visible: :all)[:"aria-checked"] == "true"
  end

  def wait_for_home_delivery(expected)
    option = expected ? "home" : "office"

    Timeout.timeout(Capybara.default_max_wait_time) do
      loop do
        break if provider.reload.home_delivery == expected

        find("label[for='delivery-#{option}']").click
        sleep 0.5
      end
    end
  end

  before do
    # El carrito del empleado se calcula contra los menús publicados, así que la
    # base se deja como está salvo los pedidos: los fixtures traen pedidos de
    # varias fechas y el criterio 5 necesita uno propio y controlado.
    OrderBenefit.delete_all
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all
  end

  def publish(menu, date, amount: 5)
    Schedule.create!(menu:, date:, amount:)
  end

  # Criterio 1 — la mitad que el modelo sí soporta: pasar de "ambas" a "solo
  # oficina". Es el recorrido real del switch, hecho en el browser.
  it "lets the provider turn home delivery off and saves it" do
    sign_in provider.user, role: :provider

    open_deliveries

    expect(home_delivery_checked?).to be(true)

    wait_for_home_delivery(false)

    expect(home_delivery_checked?).to be(false)
    expect(provider.reload.home_delivery).to be(false)
  end

  # Criterio 1 — el otro sentido: volver a habilitar el domicilio.
  it "lets the provider turn home delivery back on" do
    provider.update!(home_delivery: false)
    sign_in provider.user, role: :provider

    open_deliveries

    expect(home_delivery_checked?).to be(false)

    wait_for_home_delivery(true)

    expect(home_delivery_checked?).to be(true)
    expect(provider.reload.home_delivery).to be(true)
  end

  # Criterio 2 — persiste al volver a ingresar. El round trip completo, no solo
  # un reload: se cierra sesión y se vuelve a entrar.
  it "keeps the setting after signing out and signing in again" do
    provider.update!(home_delivery: false)
    sign_in provider.user, role: :provider

    open_deliveries
    expect(home_delivery_checked?).to be(false)

    sign_out
    visit provider_deliveries_path
    expect(page).to have_current_path(provider_sign_in_path)

    sign_in provider.user, role: :provider
    open_deliveries

    expect(home_delivery_checked?).to be(false)
    expect(provider.reload.home_delivery).to be(false)
  end

  # Criterio 2 — la configuración es del proveedor autenticado, no del rol. Dos
  # proveedores, uno cambia el suyo y el otro no se mueve.
  it "does not touch another provider's setting" do
    other_provider = providers(:endulzate)
    sign_in provider.user, role: :provider

    open_deliveries
    wait_for_home_delivery(false)

    expect(provider.reload.home_delivery).to be(false)
    expect(other_provider.reload.home_delivery).to be(true)
  end

  # Criterio 4 — la parte comprobable: un proveedor con menús publicados puede
  # desactivar el domicilio sin que sus publicaciones se caigan. El resto del
  # criterio (que no se pueda dejar sin ninguna modalidad) está diferido arriba:
  # el modelo no tiene estado "ninguna".
  it "keeps published menus available after turning home delivery off" do
    schedule = publish(menus(:milanesa), Date.current)
    sign_in provider.user, role: :provider

    open_deliveries
    wait_for_home_delivery(false)

    expect(provider.reload.home_delivery).to be(false)
    expect(schedule.reload.menu).to eq(menus(:milanesa))
    expect(Schedule.exists?(schedule.id)).to be(true)
  end

  # Transversal — permisos: la sesión de empleado no entra al área del proveedor.
  it "does not show the delivery setting to a consumer" do
    sign_in users(:one), role: :consumer

    visit provider_deliveries_path

    expect(page).to have_current_path(root_path)
    expect(page).to have_no_selector("#delivery-home")
    expect(providers(:tuviandita).reload.home_delivery).to be(true)
  end

  # Transversal — permisos: sin sesión no se llega a la pantalla.
  it "keeps a visitor with no session out of the settings" do
    visit provider_deliveries_path

    expect(page).to have_current_path(provider_sign_in_path)
    expect(page).to have_no_selector("#delivery-home")
  end
end
