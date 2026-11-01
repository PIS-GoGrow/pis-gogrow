# frozen_string_literal: true

class Admin::InertiaController < InertiaController
  skip_before_action :authenticate
  before_action -> { authenticate_role(:admin) }

  private

  def unauthenticated_path
    admin_welcome_path
  end

  # ?month=AAAA-MM. Un mes mal escrito o futuro no es un error de RR. HH.: se
  # muestra el actual.
  def selected_month
    month = Date.strptime(params[:month].to_s, "%Y-%m")
    month <= Date.current ? month : Date.current
  rescue Date::Error
    Date.current
  end

  # Las opciones del selector de mes del Inicio y de Pagos.
  def month_options(months)
    months.map { { key: it.strftime("%Y-%m"), label: I18n.l(it, format: :month_name_year) } }
  end
end
