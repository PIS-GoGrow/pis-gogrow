# frozen_string_literal: true

# Todas las pantallas son React montadas por Inertia: no hay fallback a HTML
# plano, así que rack_test no renderiza nada. Todo spec de sistema va por
# Chrome headless.
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
      # --no-sandbox solo como root: el contenedor de desarrollo corre como root y
      # el sandbox de Chrome no arranca en ese caso
      # ("Running as root without --no-sandbox is not supported", crbug.com/638180),
      # lo que hace fallar a ChromeDriver con "Chrome instance exited". Fuera del
      # contenedor el sandbox sigue aplicando.
      #
      # Van en un bloque y no en options: porque Capybara construye sus propias
      # Options para :headless_chrome y las manipula después (iguala el headless
      # con #delete), cosa que un objeto ya construido no soporta.
      options.add_argument("--no-sandbox") if Process.uid.zero?
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--disable-gpu")
    end
  end
end

# Los botones de acción de la app no tienen texto visible, solo un ícono y un
# aria-label ("Agregar <plato>", "Semana anterior"). Sin esto, find_button no
# los encuentra y habría que bajar a selectores de CSS.
Capybara.enable_aria_label = true

# El PATCH del switch de modalidad de entrega tarda varios segundos con el
# frontend real (compilación de Vite + SSR). Con el default de 2s los matchers
# expiran antes de que el server responda y el fallo se lee como "el switch no
# cambió" cuando en realidad la base sí guardó. Ningún spec usa sleep: los
# matchers de Capybara reintentan solos con este margen.
Capybara.default_max_wait_time = 15
