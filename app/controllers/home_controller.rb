# frozen_string_literal: true

class HomeController < InertiaController
  skip_before_action :authenticate
  before_action :perform_authentication

  def index
    if Current.session&.consumer?
      redirect_to dashboard_path
    elsif Current.session&.admin?
      redirect_to admin_dashboard_path
    end
  end
end
