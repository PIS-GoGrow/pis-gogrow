# frozen_string_literal: true

class OmniauthCallbacksController < InertiaController
  skip_before_action :authenticate

  # Rails only requires the CSRF token on unsafe requests (POST/PUT/DELETE).
  # This callback arrives as a GET from Google, so it doesn't apply here.
  def google_oauth2
    user = User.find_from_google(request.env["omniauth.auth"])

    if !user
      # No permitir loguearse si el usuario no existe aún
      redirect_to sign_in_path, inertia: {
        errors: { auth: t("flash.user_not_found") }
      }

      return
    end

    reset_session

    role = user.resolve_role cookies.signed[:accessing_role]&.to_sym

    if role.nil?
      # No permitir loguearse si el usuario no tiene disponible el rol que
      redirect_to sign_in_path, inertia: {
        errors: { auth: t("flash.role_not_available") }
      }

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
end
