# frozen_string_literal: true

class HomeController < InertiaController
  skip_before_action :authenticate
  before_action :perform_authentication
  before_action :redirect_to_dashboard, if: -> { Current.session }

  def index
    flash.keep
    redirect_to consumer_welcome_path
  end

  def consumer
    render_welcome("consumer")
  end

  def admin
    render_welcome("admin")
  end

  private

  def render_welcome(variant)
    @variant = variant
    @dev_login_enabled = ENV.fetch("DEV_LOGIN_ENABLED", "false") == "true"
    render_inertia "home/index", serializer: HomeIndexSerializer
  end

  def redirect_to_dashboard
    case Current.session.role
    when "consumer" then redirect_to dashboard_path
    when "provider" then redirect_to provider_dashboard_path
    when "admin" then redirect_to admin_dashboard_path
    end
  end
end
