# frozen_string_literal: true

class Settings::ProfilesController < InertiaController
  before_action :set_user

  def show
    @phone = @user.phone
  end

  def update
    if @user.update(user_params)
      redirect_to settings_profile_path, notice: t("flash.profile_updated")
    else
      redirect_to settings_profile_path, inertia: { errors: @user.errors }
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def user_params
    params.permit(:name, :phone)
  end
end
