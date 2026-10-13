# frozen_string_literal: true

# Las pantallas se renderizan en el server y React hidrata después. En esa
# ventana el HTML ya está en el DOM pero ningún manejador está montado: un clic
# temprano no hace nada y el spec falla mucho más adelante, cuando el formulario se
# manda con los datos que ese clic debería haber cambiado.
module HydrationHelpers
  # React cuelga su contenedor del nodo raíz al hidratar, y no antes.
  HYDRATED = <<~JS
    (() => {
      const app = document.getElementById("app")
      return !!app && Object.keys(app).some((key) => key.startsWith("__reactContainer"))
    })()
  JS

  # Igual que visit, pero no vuelve hasta que React está montado.
  def visit_hydrated(path)
    visit path
    wait_for_hydration
  end

  def wait_for_hydration
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.05 until page.evaluate_script(HYDRATED)
    end
  end
end

RSpec.configure do |config|
  config.include HydrationHelpers, type: :system
end
