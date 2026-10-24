# frozen_string_literal: true

# La auditoría de pedidos es de solo lectura: no hay acciones para editar ni
# borrar eventos, y OrderEvent es readonly una vez guardado.
class Admin::OrderEventsController < Admin::InertiaController
  def index
    @filters = params.permit(:order_id, :event_action, :role, :from, :to, :actor).to_h.symbolize_keys
    events = OrderEvent.where(company: Current.user.admin.company)
      .filtered(**@filters.merge(order_id: @filters[:order_id].to_s[/\d+/], from: date_param(:from), to: date_param(:to)))

    @total = events.count
    @events = events.includes(:user, order: { consumer: :user }).order(created_at: :desc, id: :desc).limit(200)
  end

  private

  def date_param(key)
    Date.iso8601(params[key].to_s)
  rescue Date::Error
    nil
  end
end
