# frozen_string_literal: true

# Elimina un plato guardado de la lista del proveedor. No se borra de la base:
# los pedidos cuelgan de la programación del plato, y sin ella el proveedor
# dejaría de verlos. Se archiva, y de hoy en adelante:
#
# - los pedidos pendientes se cancelan,
# - los confirmados se mantienen o se rechazan según elija el proveedor,
# - las programaciones sin pedidos confirmados se borran, y las que los
#   mantienen quedan sin disponibilidad, para que nadie más pida ese plato.
#
# Lo anterior a hoy no se toca: es el historial.
class Menus::Delete
  def initialize(menu:, confirmed_orders: "keep", by: nil)
    @saved = menu.saved_menu
    @reject = confirmed_orders == "reject"
    @by = by
  end

  def call
    Menu.transaction do
      @saved.lock!
      ids = @saved.family_ids

      Schedule.where(menu_id: ids, date: Date.current..).includes(:orders).find_each do |schedule|
        schedule.orders.select(&:pending?).each { it.withdraw!(by: @by) }
        schedule.orders.select(&:confirmed?).each { it.reject_for_dish_change!(reason: :dish_deleted) } if @reject

        if schedule.orders.any?(&:confirmed?)
          schedule.set_availability(available: false, by: @by)
        else
          schedule.destroy!
        end
      end

      MenuAgenda.where(menu_id: ids).destroy_all
      Menu.where(id: ids).update_all(archived_at: Time.current)
    end

    true
  end
end
