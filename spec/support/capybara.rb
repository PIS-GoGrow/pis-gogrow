# frozen_string_literal: true

# Todas las pantallas son React montadas por Inertia: no hay fallback a HTML
# plano, así que rack_test no renderiza nada. Todo spec de sistema va por
# Chrome headless.
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end
end

# Los botones de acción de la app no tienen texto visible, solo un ícono y un
# aria-label ("Agregar <plato>", "Semana anterior"). Sin esto, find_button no
# los encuentra y habría que bajar a selectores de CSS.
Capybara.enable_aria_label = true
