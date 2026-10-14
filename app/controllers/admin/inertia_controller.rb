# frozen_string_literal: true

class Admin::InertiaController < InertiaController
  skip_before_action :authenticate
  before_action -> { authenticate_role(:admin) }

  private

  # ?month=AAAA-MM. Un mes mal escrito o futuro no es un error de RR. HH.: se
  # muestra el actual.
  def selected_month
    month = Date.strptime(params[:month].to_s, "%Y-%m")
    month <= Date.current ? month : Date.current
  rescue Date::Error
    Date.current
  end
end
