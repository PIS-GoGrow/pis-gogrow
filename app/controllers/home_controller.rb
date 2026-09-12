# frozen_string_literal: true

class HomeController < InertiaController
  skip_before_action :authenticate
  before_action :perform_authentication

  def index
    if Current.user.provider?
      Current.role = :provider
    elsif Current.user.admin?
      Current.role = :admin
    elsif Current.user.consumer?
      Current.role = :consumer
    end
  end
end
