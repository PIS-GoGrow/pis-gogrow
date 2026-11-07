# frozen_string_literal: true

# El formulario de alta de platos abre con el día de hoy ya elegido en la
# agenda, que es lo que pide el diseño. Los specs que prueban el caso "sin
# ningún día" tienen que soltarlo primero, y no pueden hardcodear cuál es
# porque depende del día en que corra la suite.
module AgendaHelpers
  WEEKDAY_LABELS = %w[Lunes Martes Miércoles Jueves Viernes].freeze

  def clear_weekdays
    WEEKDAY_LABELS.each do |label|
      toggle = find("button[aria-label='#{label}']")
      toggle.click if toggle["data-state"] == "on"
    end
  end
end

RSpec.configure do |config|
  config.include AgendaHelpers, type: :system
end
