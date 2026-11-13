# frozen_string_literal: true

# El rango ?desde=AAAA-MM-DD&hasta=AAAA-MM-DD de las pantallas de métricas por
# período (Hallazgos del proveedor y Reportes de RR. HH.) y las props de su
# selector.
module SelectedPeriod
  extend ActiveSupport::Concern

  private

  # Por defecto, el mes actual. Los límites van del primer día con actividad (o
  # el inicio del mes) al fin del mes actual.
  def select_period(first_date)
    default = Date.current.all_month
    limits = [ first_date, default.first ].compact.min..default.last
    range = requested_range(limits) || default

    @from = range.first.iso8601
    @to = range.last.iso8601
    @default_from = default.first.iso8601
    @default_to = default.last.iso8601
    @min = limits.first.iso8601
    @max = limits.last.iso8601
    @month_label = (I18n.l(range.first, format: :month_name_year).capitalize if range == range.first.all_month)
    @presets = period_presets.map { |key, preset| { key:, from: preset.first.iso8601, to: preset.last.iso8601 } }

    range
  end

  # Un rango mal escrito o invertido no es un error de quien lo pide: se
  # muestra el mes actual. Lo que quede fuera de los límites se recorta.
  def requested_range(limits)
    from = Date.iso8601(params[:desde].to_s)
    to = Date.iso8601(params[:hasta].to_s)
    return if from > to

    range = [ from, limits.first ].max..[ to, limits.last ].min
    range unless range.first > range.last
  rescue Date::Error
    nil
  end

  # La semana empieza el domingo, como el calendario.
  def period_presets
    today = Date.current

    {
      today: today..today,
      yesterday: today.yesterday..today.yesterday,
      this_week: today.beginning_of_week(:sunday)..today,
      this_month: today.all_month,
      last_month: today.prev_month.all_month
    }
  end
end
