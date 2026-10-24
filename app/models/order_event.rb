# frozen_string_literal: true

# Registro de auditoría de los pedidos: quién creó o cambió cada uno, con qué
# rol, y los valores anterior y nuevo. Se escribe solo desde Order y no se
# edita ni se borra.
class OrderEvent < ApplicationRecord
  enum :role, Session.roles
  enum :action, { created: 0, modified: 1, price_changed: 2, confirmed: 3, cancelled: 4, rejected: 5 }

  belongs_to :order, optional: true
  belongs_to :company
  belongs_to :user, optional: true

  scope :filtered, ->(order_id: nil, event_action: nil, role: nil, from: nil, to: nil, actor: nil) {
    events = all
    events = events.where(order_id:) if order_id.present?
    events = events.where(action: event_action) if actions.key?(event_action)
    events = events.where(role:) if roles.key?(role)
    events = events.where(created_at: from.beginning_of_day..) if from
    events = events.where(created_at: ..to.end_of_day) if to
    events = events.where("order_events.actor_name ILIKE ?", "%#{sanitize_sql_like(actor)}%") if actor.present?
    events
  }

  def readonly? = persisted? || super
end
