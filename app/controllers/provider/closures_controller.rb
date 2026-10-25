# frozen_string_literal: true

class Provider::ClosuresController < Provider::InertiaController
  skip_before_action :require_onboarding

  def create
    closure = provider.closures.new(closure_params)
    redirect_after_save closure, closure.save
  end

  def update
    closure = provider.closures.find(params[:id])
    redirect_after_save closure, closure.update(closure_params)
  end

  def destroy
    provider.closures.find(params[:id]).destroy!
    redirect_to settings_path, notice: t("flash.provider_closure_deleted")
  end

  private

  def settings_path
    return provider_onboarding_path(step: 2) if params[:onboarding].present?

    provider_operational_settings_path
  end

  def provider
    @provider ||= Current.user.provider
  end

  def closure_params
    params.permit(:starts_on, :ends_on, :reason)
  end

  def redirect_after_save(closure, saved)
    if saved
      redirect_to settings_path
    else
      redirect_to settings_path, inertia: { errors: closure.errors }
    end
  end
end
