# frozen_string_literal: true

class Provider::OrderDeadlinesController < Provider::InertiaController
  def update
    if invalid_order_deadline?
      provider.errors.add(:order_deadline, t("validations.invalid_order_deadline"))
      redirect_to provider_dashboard_path, inertia: { errors: provider.errors }
    elsif provider.update(order_deadline: parsed_order_deadline)
      redirect_to provider_dashboard_path, notice: t("flash.order_deadline_updated")
    else
      redirect_to provider_dashboard_path, inertia: { errors: provider.errors }
    end
  end

  private

  def provider
    @provider ||= Current.user.provider
  end

  def order_deadline
    params.permit(:order_deadline)[:order_deadline].to_s
  end

  def invalid_order_deadline?
    order_deadline.present? && !order_deadline.match?(/\A(?:[01]\d|2[0-3]):[0-5]\d\z/)
  end

  def parsed_order_deadline
    return if order_deadline.blank?

    hours, minutes = order_deadline.split(":").map(&:to_i)
    Time.zone.local(2000, 1, 1, hours, minutes)
  end
end
