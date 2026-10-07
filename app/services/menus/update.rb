# frozen_string_literal: true

# Aplica la edición de un plato según cómo esté programado. La agenda del
# formulario dice a qué fechas llegan los cambios:
#
# - none: sin días elegidos. Cambia el plato guardado de hoy en adelante y le
#   saca la agenda.
# - single: un día. Con scope "day" solo cambia la programación de ese día; con
#   scope "saved" cambia el plato guardado desde ese día.
# - weekly: cambia el plato guardado desde starts_on y desde ahí rige la agenda
#   nueva.
# - range: los cambios valen de starts_on a ends_on, con su propia agenda; después
#   el plato vuelve a su configuración anterior.
#
# Los cambios a una fecha que no son del plato guardado viven en una variante
# (ver Menu). Las programaciones anteriores al cambio se pasan a una variante con
# los datos viejos, así no cambian lo que ya estaba publicado. Los pedidos
# guardan su propia copia del plato, así que el historial no cambia; los
# confirmados de las fechas afectadas se mantienen o se rechazan según elija el
# proveedor.
class Menus::Update
  MODES = %w[none single weekly range].freeze

  attr_reader :errors

  def initialize(menu:, attributes:, agenda:, scope: nil, confirmed_orders: "keep", by: nil)
    @saved = menu.saved_menu
    @attributes = attributes
    @agenda = agenda.to_h.symbolize_keys
    @scope = scope
    @reject = confirmed_orders == "reject"
    @by = by
    @errors = ActiveModel::Errors.new(@saved)
  end

  def call
    return false unless valid_agenda?

    Menu.transaction do
      @saved.lock!
      affected = affected_schedules.includes(:orders).to_a

      case mode
      when "none" then apply_from(Date.current, agenda: nil)
      when "weekly" then apply_from(starts_on, agenda: new_agenda(ends_on: nil))
      when "range" then apply_range
      when "single" then day_scope? ? apply_day : apply_from(date, agenda: :keep)
      end

      ensure_schedule(date) if mode == "single"
      reject_confirmed(affected) if @reject
      Menus::AgendaScheduler.call(@saved)
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each { |error| @errors.add(error.attribute, error.message) }
    false
  end

  def affected_schedules
    family = Schedule.where(menu_id: @saved.family_ids)

    case mode
    when "single" then day_scope? ? family.where(date:) : family.where(date: [ date, Date.current ].max..)
    when "range" then family.where(date: [ starts_on, Date.current ].max..ends_on)
    when "weekly" then family.where(date: [ starts_on, Date.current ].max..)
    else family.where(date: Date.current..)
    end
  end

  private

  def mode = MODES.include?(@agenda[:mode]) ? @agenda[:mode] : "none"
  def day_scope? = @scope == "day"
  def date = parse(:date)
  def starts_on = parse(:starts_on)
  def ends_on = parse(:ends_on)
  def weekdays = Array(@agenda[:weekdays]).map(&:to_i).uniq.sort

  def parse(key)
    Date.iso8601(@agenda[key].to_s)
  rescue Date::Error
    nil
  end

  def valid_agenda?
    case mode
    when "single"
      add_agenda_error(:invalid_date) unless date && date >= Date.current && date.on_weekday? && date <= Calendar.new.maximum_publish_date
    when "weekly", "range"
      add_agenda_error(:invalid_date) unless starts_on && starts_on >= Date.current
      add_agenda_error(:invalid_range) if mode == "range" && !(ends_on && starts_on && ends_on >= starts_on)
    end

    if mode != "none"
      add_agenda_error(:invalid_amount) unless new_agenda(ends_on: nil).tap(&:validate).errors[:amount].empty?
      add_agenda_error(:invalid_weekdays) if mode != "single" && (weekdays.empty? || !weekdays.all? { (1..5).cover?(it) })
    end

    @errors.empty?
  end

  def add_agenda_error(type)
    @errors.add(:agenda, I18n.t("validations.menu_agenda.#{type}"))
  end

  def new_agenda(ends_on:)
    MenuAgenda.new(weekdays:, starts_on: starts_on || date, ends_on:, amount: @agenda[:amount])
  end

  # Desde `from` los cambios van al plato guardado. Lo programado entre hoy y
  # `from` queda con los datos de antes.
  def apply_from(from, agenda:)
    from = [ from, Date.current ].max
    preserve_until(from) if from > Date.current
    carve(from)

    unless agenda == :keep
      close_agendas(from)
      agenda&.tap { it.menu = @saved }&.save!
      @saved.skipped_dates = @saved.skipped_dates.reject { it >= from } if agenda
    end

    assign(@saved)
    record_audit(@saved)
    @saved.save!
  end

  def apply_range
    carve(starts_on, ends_on)
    @saved.update!(skipped_dates: @saved.skipped_dates.reject { (starts_on..ends_on).cover?(it) })
    variant = build_edited_variant(starts_on, ends_on)
    variant.agendas.build(weekdays:, starts_on:, ends_on:, amount: @agenda[:amount])
    variant.save!
    Schedule.where(menu_id: @saved.id, date: starts_on..ends_on).update_all(menu_id: variant.id)
  end

  def apply_day
    carve(date, date)
    variant = build_edited_variant(date, date)
    variant.save!
    Schedule.where(menu_id: @saved.id, date:).update_all(menu_id: variant.id)
  end

  def ensure_schedule(date)
    @saved.update!(skipped_dates: @saved.skipped_dates - [ date ])
    return if Schedule.exists?(menu_id: @saved.family_ids, date:)

    target = Menu.where(base_menu_id: @saved.id).find { it.valid_on?(date) } || @saved
    target.schedules.create!(date:, amount: @agenda[:amount])
  end

  def build_edited_variant(from, to)
    @saved.build_variant(valid_from: from, valid_until: to).tap do |variant|
      variant.option_groups = []
      assign(variant)
      diff = %w[name description price].each_with_object({}) do |attr, hash|
        old_val = @saved.public_send(attr)
        new_val = variant.public_send(attr)
        hash[attr] = [ old_val, new_val ] if old_val.to_s != new_val.to_s
      end
      variant.modified_by = @by if @by
      variant.modified_at = Time.current
      variant.modified_values = diff if diff.present?
    end
  end

  def preserve_until(from)
    old_schedules = @saved.schedules.where(date: Date.current...from)
    return if old_schedules.none? && @saved.agendas.none?

    frozen = @saved.build_variant(valid_from: Date.current, valid_until: from - 1)
    frozen.save!
    old_schedules.update_all(menu_id: frozen.id)
  end

  def close_agendas(from)
    @saved.agendas.where(starts_on: from..).destroy_all
    @saved.agendas.where(starts_on: ...from).where(ends_on: nil).or(
      @saved.agendas.where(starts_on: ...from, ends_on: from..)
    ).find_each { it.update!(ends_on: from - 1) }
  end

  # Saca el período from..to (o desde `from` en adelante) de las variantes que
  # lo cubran, y devuelve al plato guardado sus programaciones de ese período.
  def carve(from, to = nil)
    variants = @saved.variants.includes(:agendas).where(valid_until: from..)
    variants = variants.where(valid_from: ..to) if to

    variants.each do |variant|
      starts_inside = variant.valid_from >= from
      ends_inside = to.nil? || variant.valid_until <= to

      if starts_inside && ends_inside
        variant.schedules.update_all(menu_id: @saved.id)
        variant.destroy!
        next
      end

      if !starts_inside && !ends_inside
        tail = variant.build_variant(valid_from: to + 1, valid_until: variant.valid_until)
        variant.agendas.each { tail.agendas.build(weekdays: it.weekdays, starts_on: to + 1, ends_on: variant.valid_until, amount: it.amount) }
        tail.save!
        variant.schedules.where(date: (to + 1)..).update_all(menu_id: tail.id)
      end

      period = to ? from..to : from..
      variant.schedules.where(date: period).update_all(menu_id: @saved.id)

      if starts_inside
        variant.update!(valid_from: to + 1)
        variant.agendas.each { it.update!(starts_on: to + 1) }
      else
        variant.update!(valid_until: from - 1)
        variant.agendas.each { it.update!(ends_on: from - 1) }
      end
    end
  end

  # Si el formulario trae los grupos del mismo plato, van con sus ids. Si trae los
  # de otro (se editó una variante y los cambios van al plato guardado, o al
  # revés), se reemplazan por copias.
  def assign(menu)
    menu.assign_attributes(@attributes.slice(:name, :description, :price))
    groups = Array(@attributes[:option_groups_attributes])
    ids = groups.filter_map { it[:id]&.to_i }

    if menu.persisted? && (ids - menu.option_group_ids).empty?
      menu.assign_attributes(option_groups_attributes: groups)
      return
    end

    menu.option_groups.each(&:mark_for_destruction)
    groups.reject { ActiveModel::Type::Boolean.new.cast(it[:_destroy]) }
          .each { menu.option_groups.build(name: it[:name], options: Array(it[:options]), limit: it[:limit]) }
  end

  def reject_confirmed(schedules)
    schedules.flat_map(&:orders).select(&:confirmed?).each(&:reject_for_dish_change!)
  end

  def record_audit(record)
    changes = record.changes.slice("name", "description", "price")
    return if changes.blank? && @by.nil?

    record.modified_by = @by if @by
    record.modified_at = Time.current
    record.modified_values = changes if changes.present?
  end
end
