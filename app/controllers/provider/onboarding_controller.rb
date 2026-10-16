# frozen_string_literal: true

class Provider::OnboardingController < Provider::InertiaController
  skip_before_action :require_onboarding

  STEPS = 4

  def show
    @provider = provider
    @step = current_step
    @notification_configurations = provider_notification_configurations
    @subscribed_keys =
      @notification_configurations
        .joins(:notification_configuration_users)
        .where(notification_configuration_users: { user_id: Current.user.id })
        .pluck(:key)
  end

  def update
    step = params[:step].to_i
    advance(step) if skipping? || save_step(step)
  end

  private

  def provider
    @provider ||= Current.user.provider
  end

  def current_step
    return "done" if provider.onboarded?

    (params[:step].presence_in(%w[1 2 3 4]) || "1")
  end

  def skipping?
    params[:commit] == "skip"
  end

  def advance(step)
    if step >= STEPS
      provider.update(onboarding_completed_at: Time.current) unless provider.onboarded?
      redirect_to provider_onboarding_path(step: "done")
    else
      redirect_to provider_onboarding_path(step: step + 1)
    end
  end

  def save_step(step)
    case step
    when 1 then save_payment_details
    when 2 then save_order_deadline
    when 3 then save_deliveries
    when 4 then save_notifications
    else true
    end
  end

  def save_payment_details
    provider.assign_attributes(
      params.expect(provider: [ :bank_name, :bank_account_type, :bank_account_number, :bank_account_holder, :tax_id ])
    )
    save_or_redirect provider.save(context: :payment_details), 1
  end

  def save_order_deadline
    value = params[:order_deadline].to_s

    if value.blank?
      true
    elsif value.match?(/\A(?:[01]\d|2[0-3]):[0-5]\d\z/)
      hours, minutes = value.split(":").map(&:to_i)
      provider.update(order_deadline: Time.zone.local(2000, 1, 1, hours, minutes))
    else
      provider.errors.add(:order_deadline, t("validations.invalid_order_deadline"))
      save_or_redirect false, 2
    end
  end

  def save_deliveries
    provider.update(home_delivery: ActiveModel::Type::Boolean.new.cast(params[:home_delivery]))
  end

  def save_notifications
    subscribed_ids = Array(params[:subscribed_ids]).map(&:to_i)

    provider_notification_configurations.find_each do |config|
      subscribed = config.notification_configuration_users.exists?(user_id: Current.user.id)
      if subscribed_ids.include?(config.id) && !subscribed
        config.users << Current.user
      elsif !subscribed_ids.include?(config.id) && subscribed
        config.users.destroy(Current.user)
      end
    end

    true
  end

  def save_or_redirect(saved, step)
    redirect_to provider_onboarding_path(step:), inertia: { errors: provider.errors } unless saved
    saved
  end

  def provider_notification_configurations
    Notification::Configuration.where(configurable: true).for_role(:provider)
  end
end
