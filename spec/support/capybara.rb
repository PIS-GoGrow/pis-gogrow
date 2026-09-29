# frozen_string_literal: true

# Todas las pantallas son React montadas por Inertia: no hay fallback a HTML
# plano, así que rack_test no renderiza nada. Todo spec de sistema va por
# Chrome headless.
# Si se usa la bandera USE_FIREFOX, se usa Firefox en vez de chrome (es un
# workaround porque en Mac Selenium con Chrome no funciona)
RSpec.configure do |config|
  config.before(:each, type: :system) do
    browser = ENV["USE_FIREFOX"] ? :firefox : :headless_chrome

    driven_by :selenium, using: browser, screen_size: [ 1400, 1400 ] do |driver_option|
      driver_option.add_argument("--no-sandbox")
      driver_option.add_argument("--disable-dev-shm-usage")
      driver_option.add_argument("--disable-gpu")
    end
  end
end


# Los botones de acción de la app no tienen texto visible, solo un ícono y un
# aria-label ("Agregar <plato>", "Semana anterior"). Sin esto, find_button no
# los encuentra y habría que bajar a selectores de CSS.
Capybara.enable_aria_label = true
Capybara.default_max_wait_time = 10
