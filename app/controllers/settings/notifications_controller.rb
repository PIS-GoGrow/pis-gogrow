# frozen_string_literal: true

class Settings::NotificationsController < InertiaController
  before_action :authenticate
  wrap_parameters false

  def index
    @notification_configurations =
      Notification::Configuration
        .where(configurable: true)
        .for_role Current.session.role
    @subscribed_keys =
      @notification_configurations
        .joins(:notification_configuration_users)
        .where(notification_configuration_users: { user_id: Current.user.id })
        .pluck :key
  end

  def update
    config = Notification::Configuration.for_role(Current.session.role).find_by id: config_params[:id]
    return redirect_to settings_notifications_path, alert: I18n.t("flash.config_update_error") unless config

    if config_params[:subscribe]
      config.users << Current.user
    else
      config.users.destroy Current.user
    end

    redirect_to settings_notifications_path, notice: I18n.t("flash.config_update")
  rescue ActiveRecord::ActiveRecordError => error
    Rails.logger.error("[Settings::NotificationsController] #{error.class}: #{error.message}")
    redirect_to settings_notifications_path, alert: I18n.t("flash.config_update_error")
  end

  private

  def config_params
    params.permit :subscribe, :id
  end
end
