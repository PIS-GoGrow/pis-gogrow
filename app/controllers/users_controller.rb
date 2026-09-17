# frozen_string_literal: true

class UsersController < InertiaController
  skip_before_action :authenticate, only: %i[new create]
  before_action :require_no_authentication, only: %i[new create]

  def new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      send_email_verification
      redirect_to sign_in_path, alert: t("flash.role_not_available")
    else
      redirect_to sign_up_path, inertia: { errors: @user.errors }
    end
  end

  def destroy
    user = Current.user
    if user.authenticate(params[:password_challenge] || "")
      user.destroy!
      Current.session = nil
      redirect_to root_path, notice: t("flash.user_deleted"), inertia: { clear_history: true }
    else
      redirect_to settings_profile_path, inertia: { errors: { password_challenge: t("validations.password_challenge_invalid") } }
    end
  end

  private

  def user_params
    params.permit(:email, :name, :password, :password_confirmation)
  end

  def send_email_verification
    UserMailer.with(user: @user).email_verification.deliver_later
  end
end
