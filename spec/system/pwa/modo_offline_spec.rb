# frozen_string_literal: true

require "rails_helper"

# IBP-111: sin conexión, el service worker responde con /offline, que muestra
# los pedidos guardados en IndexedDB la última vez que hubo red.
RSpec.describe "Modo offline (PWA)" do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules, :orders

  after do
    go_online
    # El perfil de Chrome se reusa entre specs: sin esto el service worker y
    # los pedidos guardados pasan al siguiente.
    page.driver.browser.execute_cdp("Storage.clearDataForOrigin", origin: Capybara.current_session.server.base_url, storageTypes: "all")
  end

  def wait_for_offline_page_cached
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.1 until page.evaluate_async_script(<<~JS)
        const done = arguments[0];
        navigator.serviceWorker.getRegistration()
          .then((reg) => reg && reg.active ? caches.match("/offline") : null)
          .then((res) => done(!!res), () => done(false));
      JS
    end
  end

  def cached_orders(store)
    page.evaluate_async_script(<<~JS, store)
      const [store, done] = arguments;
      const open = indexedDB.open("app-offline");
      open.onsuccess = () => {
        const db = open.result;
        if (!db.objectStoreNames.contains(store)) return done(0);
        const get = db.transaction(store).objectStore(store).get(1);
        get.onsuccess = () => done(get.result ? get.result.upcoming_orders.length : 0);
        get.onerror = () => done(0);
      };
      open.onerror = () => done(0);
    JS
  end

  def wait_for_cached_orders(store, count)
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.1 until cached_orders(store) == count
    end
  end

  def go_offline
    page.driver.browser.network_conditions = { offline: true, latency: 0, throughput: 0 }
  end

  def go_online
    page.driver.browser.network_conditions = { offline: false, latency: 0, throughput: -1 }
  end

  def reload_offline(path)
    go_offline
    visit path
    expect(page).to have_content("Estás sin conexión")
  end

  def sign_out_from_app(user)
    find("[data-sidebar='menu-button']", text: user.name).click
    click_on "Cerrar sesión"
  end

  it "muestra la página sin conexión y al reintentar con red vuelve a la página" do
    sign_in users(:one), role: :consumer
    visit_hydrated dashboard_path
    wait_for_offline_page_cached

    reload_offline dashboard_path
    expect(page).to have_button("Reintentar")
    expect(page).to have_no_content("Pedidos realizados")

    go_online
    click_on "Reintentar"

    expect(page).to have_no_content("Estás sin conexión")
    expect(page).to have_current_path(dashboard_path)
  end

  it "le muestra al consumidor sus pedidos próximos de la última vez que tuvo red" do
    sign_in users(:one), role: :consumer
    visit_hydrated orders_path
    wait_for_offline_page_cached
    wait_for_cached_orders("consumer_orders", 3)

    reload_offline orders_path

    expect(page).to have_content("Pedidos realizados")
    expect(page).to have_content("Sus estados pueden haber cambiado")
    expect(page).to have_content("Milanesa con papas fritas x2")
    expect(page).to have_content("Confirmado")
    expect(page).to have_no_content("Cancelado")
    expect(page).to have_no_content("Rechazado")
  end

  it "guarda el pedido recién confirmado aunque el consumidor no pase por Mis pedidos" do
    order = orders(:upcoming_pending_today)
    order.update_columns(amount: 7)

    sign_in users(:one), role: :consumer
    visit_hydrated dashboard_confirmation_path(confirmed_order_ids: [ order.id ])
    wait_for_offline_page_cached
    wait_for_cached_orders("consumer_orders", 3)

    reload_offline dashboard_path

    expect(page).to have_content("Pedidos realizados")
    expect(page).to have_content("Milanesa con papas fritas x7")
  end

  it "le muestra al proveedor los pedidos recibidos de la última vez que tuvo red" do
    sign_in users(:provider_user), role: :provider
    visit_hydrated provider_orders_path
    wait_for_offline_page_cached
    Timeout.timeout(Capybara.default_max_wait_time) { sleep 0.1 until cached_orders("provider_orders").positive? }

    reload_offline provider_orders_path

    expect(page).to have_content("Pedidos pendientes recibidos")
    expect(page).to have_content("Test User")
    expect(page).to have_content("Other Consumer User")
  end

  it "no muestra pedidos guardados después de cerrar sesión" do
    sign_in users(:one), role: :consumer
    visit_hydrated orders_path
    wait_for_offline_page_cached
    wait_for_cached_orders("consumer_orders", 3)

    sign_out_from_app(users(:one))
    expect(page).to have_current_path(consumer_welcome_path)
    wait_for_cached_orders("consumer_orders", 0)

    reload_offline orders_path
    expect(page).to have_no_content("Pedidos realizados")
    expect(page).to have_no_content("Milanesa con papas fritas")
  end

  it "no le muestra a otro consumidor del mismo navegador los pedidos del anterior" do
    sign_in users(:one), role: :consumer
    visit_hydrated orders_path
    wait_for_offline_page_cached
    wait_for_cached_orders("consumer_orders", 3)

    sign_out
    sign_in users(:other_consumer_user), role: :consumer
    visit_hydrated orders_path
    wait_for_cached_orders("consumer_orders", 1)

    reload_offline orders_path
    expect(page).to have_content("Bulevar Artigas 1234")
    expect(page).to have_no_content("Julio Herrera y Reissig 565")
  end
end
