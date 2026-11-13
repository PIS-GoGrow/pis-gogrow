# frozen_string_literal: true

# Los selectores de fecha de la agenda son un popover con un calendario, no un
# input: no se pueden completar con fill_in. react-day-picker rotula cada día con
# la fecha larga en español ("jueves, 15 de octubre de 2026"), así que el día se
# busca por ese rótulo y no por su posición en la grilla.
module DatePickerHelpers
  # El popover sigue en el DOM después de cerrarse, así que hay que apuntar al que
  # está abierto: si no, within se engancha al calendario cerrado.
  OPEN_CALENDAR = "[data-slot=popover-content][data-state=open] [data-slot=calendar]"

  # Rails y date-fns capitalizan distinto: Rails pone "Octubre" y el calendario
  # "octubre", así que hay que igualar.
  def day_label(date)
    I18n.l(date, format: "%A, %-d de %B de %Y", locale: :es).downcase
  end

  # El calendario decora el rótulo con "Hoy, " en el día corriente y con
  # ", seleccionado" en el elegido, así que la comparación va contra el texto
  # pelado. Busca dentro del calendario abierto: llama desde dentro de él.
  def day_button(date)
    plain = day_label(date)

    3.times do
      btn = all("button.rdp-day").find do |button|
        button[:'aria-label'].to_s.delete_prefix("Hoy, ").split(", seleccionado").first == plain
      end
      return btn if btn

      sleep 0.05
    end

    nil
  end

  # Marca un día de la semana y espera a que quede marcado.
  def select_weekday(name)
    button = find("button[aria-label='#{name}']")
    button.click unless button[:'data-state'] == "on"
    expect(find("button[aria-label='#{name}'][data-state='on']")).to be_present
  end

  # Deja marcados exactamente los días indicados: el formulario abre con los que
  # ya tenía la agenda vigente, así que primero hay que apagar los que sobran.
  def set_weekdays(*names)
    names.each { select_weekday(_1) }

    weekday_buttons.each do |button|
      next if names.include?(button[:'aria-label'])

      button.click if button[:'data-state'] == "on"
      expect(button[:'data-state']).to eq("off")
    end
  end

  def weekday_buttons
    page.all("[data-slot='toggle-group'] button")
  end

  # Igual que select_weekday, pero además espera al selector de fecha, que solo se
  # monta con el primer día elegido. Sin esa espera el formulario se puede mandar
  # con la agenda todavía vacía.
  def choose_weekday(name)
    select_weekday(name)
    expect(find("#agenda-date")).to be_present
  end

  # El disparador puede estar entrando con la animación del Sheet (500 ms) y un
  # clic sobre un elemento en movimiento apunta a una posición que ya no existe.
  def open_date_picker(trigger)
    wait_until_settled trigger
    3.times do
      find(trigger).click
      break if page.has_css?(OPEN_CALENDAR, wait: 0.5)
    end
    expect(page).to have_css(OPEN_CALENDAR)
  end

  def wait_until_settled(trigger)
    previous = nil

    Timeout.timeout(Capybara.default_max_wait_time) do
      loop do
        current = page.evaluate_script(<<~JS)
          (() => {
            const el = document.querySelector(#{trigger.to_json})
            if (!el) return null
            const rect = el.getBoundingClientRect()
            return [Math.round(rect.x), Math.round(rect.y)]
          })()
        JS
        break if current && current == previous

        previous = current
        sleep 0.05
      end
    end
  end

  # El disparador es un toggle: si el calendario quedó abierto de una consulta
  # anterior, un clic lo cerraría en vez de abrirlo.
  def close_date_picker(trigger)
    return unless page.has_css?(OPEN_CALENDAR, wait: 0)

    find(trigger).click
    expect(page).to have_no_css(OPEN_CALENDAR)
  end

  # Obtiene el mes actualmente visible en el calendario leyendo los controles
  # nativos o las celdas del mes en el DOM.
  def visible_month
    year, month = page.evaluate_script(<<~JS)
      (() => {
        const cal = document.querySelector(#{OPEN_CALENDAR.to_json})
        if (!cal) return null
        const monthSelect = cal.querySelector('select.rdp-months_dropdown')
        const yearSelect = cal.querySelector('select.rdp-years_dropdown')
        if (monthSelect && yearSelect) {
          return [parseInt(yearSelect.value, 10), parseInt(monthSelect.value, 10) + 1]
        }
        const cell = cal.querySelector('td[role=gridcell]:not([data-outside=true])')
        if (cell && cell.dataset.month) {
          const parts = cell.dataset.month.split('-')
          return [parseInt(parts[0], 10), parseInt(parts[1], 10)]
        }
        return null
      })()
    JS
    Date.new(year, month, 1) if year && month
  end

  # Navega hasta el mes del día buscado basándose en el mes que realmente está
  # a la vista en el calendario.
  def show_month(date, opens_at = Date.current)
    target = date.beginning_of_month

    24.times do
      visible = visible_month || opens_at.beginning_of_month
      return true if visible == target

      forward = visible < target
      find("button[aria-label='Ir al mes #{forward ? 'siguiente' : 'anterior'}']").click

      expected = visible >> (forward ? 1 : -1)
      Timeout.timeout(Capybara.default_max_wait_time) do
        loop do
          break if visible_month == expected

          sleep 0.05
        end
      end
    end

    false
  end

  # React vuelve a renderizar el calendario entre que se busca el día y se lo
  # cliquea, y el elemento encontrado queda viejo. Hay que volver a buscarlo.
  def click_day(date)
    3.times do
      begin
        return day_button(date)&.click
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        next
      end
    end

    raise "No se pudo elegir el día #{date}"
  end

  def pick_date(trigger, date, opens_at: Date.current)
    open_date_picker trigger

    within OPEN_CALENDAR do
      raise "El calendario no llegó a mostrar #{date}" unless show_month(date, opens_at)

      click_day date
    end
  end

  # Abre el calendario y mira el día sin elegirlo: es la única forma de
  # comprobar si la fecha está habilitada.
  def date_disabled?(trigger, date, opens_at: Date.current)
    open_date_picker trigger

    within OPEN_CALENDAR do
      show_month(date, opens_at)
      day_button(date)&.[](:disabled) == "true"
    end
  ensure
    close_date_picker trigger
  end
end

RSpec.configure do |config|
  config.include DatePickerHelpers, type: :system
end
