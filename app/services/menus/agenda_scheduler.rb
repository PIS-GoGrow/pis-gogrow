# frozen_string_literal: true

# Crea las programaciones que piden las agendas de un plato hasta la fecha
# máxima de publicación. Es idempotente: una fecha en la que el plato o alguna de
# sus variantes ya está programado, o que el proveedor quitó, no se toca.
#
# Durante el rango de una variante con agenda manda esa agenda y no la del plato
# guardado. Fuera de esos rangos, la agenda del plato guardado programa la
# variante sin agenda que cubra la fecha, si hay, o el plato guardado.
class Menus::AgendaScheduler
  def self.call(menu)
    new(menu.saved_menu).call
  end

  def self.call_all
    Menu.saved.find_each { new(it).call }
  end

  def initialize(saved_menu)
    @menu = saved_menu
    @limit = Calendar.new.maximum_publish_date
  end

  def call
    taken = Schedule.where(menu_id: @menu.family_ids, date: Date.current..).pluck(:date).to_set
    taken.merge(@menu.skipped_dates)
    ranged, plain = @menu.variants.includes(:agendas).order(id: :desc).partition { it.agendas.any? }

    ranged.each do |variant|
      variant.agendas.each { |agenda| program(variant, agenda, taken) }
    end

    @menu.agendas.each do |agenda|
      program(@menu, agenda, taken) do |date|
        next if ranged.any? { it.valid_on?(date) }

        plain.find { it.valid_on?(date) } || @menu
      end
    end
  end

  private

  def program(menu, agenda, taken)
    agenda.dates_until(@limit).each do |date|
      next if taken.include?(date)

      target = block_given? ? yield(date) : menu
      next if target.nil?

      target.schedules.create!(date:, amount: agenda.amount)
      taken << date
    end
  end
end
