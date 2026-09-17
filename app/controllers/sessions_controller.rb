# frozen_string_literal: true

class SessionsController < InertiaController
  skip_before_action :authenticate, only: %i[new create]
  before_action :require_no_authentication, only: %i[new create]
  before_action :set_session, only: %i[edit update destroy]

  def new
  end

  def create
    if (user = User.authenticate_by(email: params[:email], password: params[:password]))
      user.sync_roles!

      if user.roles.empty?
        redirect_to sign_in_path, alert: t("flash.role_not_available")
        return
      end

      role = user.roles.first.to_sym
      @session = user.sessions.create!(role: role)
      cookies.signed.permanent[:session_token] = { value: @session.id, httponly: true }

      redirect_to dashboard_path, notice: t("flash.signed_in")
    else
      redirect_to sign_in_path, alert: t("flash.incorrect_credentials")
    end
  end

  def edit
    render inertia: { roles: Current.user.roles, id: params[:id] }
  end

  # De una sesión solo se puede editar el rol efectivo del usuario
  def update
    new_role = params[:role]

    if Current.user.roles.include?(new_role) && Current.session.update(role: new_role)
      redirect_to root_path, notice: t("flash.role_set")
    else
      redirect_to root_path, alert: t("flash.role_not_available")
    end
  end

  def destroy
    @session.destroy!
    Current.session = nil
    redirect_to root_path, notice: t("flash.session_logged_out"), inertia: { clear_history: true }
  end

  private

  def set_session
    @session = Current.user.sessions.find(params[:id])
  end
end
