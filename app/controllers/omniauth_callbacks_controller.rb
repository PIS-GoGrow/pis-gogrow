# frozen_string_literal: true

class OmniauthCallbacksController < InertiaController
  skip_before_action :authenticate

  # Rails only requires the CSRF token on unsafe requests (POST/PUT/DELETE).
  # This callback arrives as a GET from Google, so it doesn't apply here.
  def google_oauth2
    user = User.find_or_create_from_google(request.env["omniauth.auth"])

    reset_session

    role = determine_role(user)

    if role.nil?
      redirect_to root_path, alert: "Rol no disponible"
      return
    end

    @session = user.sessions.create! role: role

    cookies.signed.permanent[:session_token] = { value: @session.id, httponly: true }
    cookies.delete(:accessing_role)

    redirect_to root_path, notice: t("flash.signed_in")
  rescue User::DomainNotAllowed
    redirect_to sign_in_path, inertia: {
      errors: { auth: t("flash.google_domain_not_allowed") }
    }
  end

  # OmniAuth.config.on_failure redirects here on any failure in the flow
  # (the person cancels the Google consent screen, invalid credentials, etc).
  def failure
    redirect_to sign_in_path, inertia: {
      errors: { auth: t("flash.google_auth_failed") }
    }
  end

  private

  def determine_role(user)
    role = cookies.signed[:accessing_role]

    if (role == :provider || role == nil) && user.provider?
      :provider
    elsif (role == :consumer || role == nil) && user.consumer?
      :consumer
    elsif (role == :admin || role == nil) && user.admin?
      :admin
    else
      nil
    end
  end
end
