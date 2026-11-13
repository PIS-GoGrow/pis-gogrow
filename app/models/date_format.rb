# frozen_string_literal: true

# Formato único de fechas de toda la app, con dos variantes (el front usa el
# mismo criterio en app/javascript/lib/dates.ts):
#
#   DateFormat.long(Date.new(2026, 10, 12)) # => "Lunes 12 de octubre"
#   DateFormat.long(Date.new(2026, 10, 12), inline: true) # => "lunes 12 de octubre"
#   DateFormat.short(Date.new(2026, 11, 5)) # => "05/11/26"
#
# El largo se usa en los textos con fechas (con inline: true cuando la fecha va en
# medio de una frase, así el día de la semana va en minúscula) y el corto en datos
# sueltos (columnas, "Vence: ...") y en los rangos.
# Los formatos viven en config/locales/es.yml (date.formats.long y .short).
module DateFormat
  module_function

  def long(date, inline: false)
    return if date.nil?

    # El locale escribe los meses con mayúscula ("Octubre"): se pasa todo a
    # minúscula y, salvo que vaya dentro de una frase, solo la primera letra a
    # mayúscula.
    text = I18n.l(date.to_date, format: :long).downcase
    inline ? text : text.capitalize
  end

  def short(date)
    return if date.nil?

    I18n.l(date.to_date, format: :short)
  end

  # Para momentos exactos: "Jueves 5 de noviembre a las 14:30".
  def long_with_time(time, inline: false)
    return if time.nil?

    "#{long(time, inline:)} a las #{time.strftime("%H:%M")}"
  end

  # Rango de fechas: "19/10/26 al 21/10/26", o una sola fecha si es un día.
  def short_range(from, to)
    return short(from) if from == to

    "#{short(from)} al #{short(to)}"
  end
end
