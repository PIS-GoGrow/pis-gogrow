# frozen_string_literal: true

# Todas las pantallas son React montadas por Inertia: no hay fallback a HTML
# plano, así que rack_test no renderiza nada. Todo spec de sistema va por
# Chrome headless.
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
      # El sandbox de Chrome no puede arrancar como root y el contenedor de
      # desarrollo corre como root. Solo se desactiva en ese caso: fuera del
      # contenedor (root no root) el sandbox sigue aplicando.
      options.add_argument("--no-sandbox") if Process.uid.zero?
      options.add_argument("--disable-dev-shm-usage")
    end
  end
end

# Los botones de acción de la app no tienen texto visible, solo un ícono y un
# aria-label ("Agregar <plato>", "Semana anterior"). Sin esto, find_button no
# los encuentra y habría que bajar a selectores de CSS.
Capybara.enable_aria_label = true

# El server de desarrollo con Vite responde mucho más lento que uno de test: el
# panel de detalle de /accounts pide /accounts/:id por fetch, y la subida del
# comprobante (multipart contra Puma en development) tarda por sí sola ~10s. Con
# los 2s por defecto la aserción gana antes de que llegue la respuesta.
Capybara.default_max_wait_time = 30
