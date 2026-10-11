# frozen_string_literal: true

# Publica platos guardados en una fecha: crea la programación de cada plato ese
# día. Es lo mismo que hace Menus::Update#ensure_schedule al elegir "un solo
# día", pero sin tocar los datos del plato. Si el plato ya estaba publicado esa
# fecha no hace nada

class Menus::Publish
  attr_reader :errors

  def initialize(provider:, menu_ids:, date:)
    @provider = provider
    @menu_ids = Array(menu_ids).map(&:to_i).uniq
    @date = parse(date)
    @errors = ActiveModel::Errors.new(Menu.new)
  end

  def call
    return false unless valid?

    Menu.transaction do
      @menus.each { publish(it) }
    end

    true
  end

  private

  def valid?
    unless @date && @date >= Date.current && @date.on_weekday? && @date <= Calendar.new.maximum_publish_date
      @errors.add(:date, I18n.t("validations.menu_publish.invalid_date"))
    end

    @menus = @provider.menus.saved.where(id: @menu_ids).to_a
    @errors.add(:menu_ids, I18n.t("validations.menu_publish.invalid_menus")) if @menus.empty? || @menus.size != @menu_ids.size

    @errors.empty?
  end

  def publish(saved)
    saved.lock!
    return if Schedule.exists?(menu_id: saved.family_ids, date: @date)

    # Si el proveedor lo había quitado a mano, la agenda no lo debe seguir salteando.
    saved.update!(skipped_dates: saved.skipped_dates - [ @date ])

    target = saved.variants.find { it.valid_on?(@date) } || saved
    target.schedules.create!(date: @date)
  end

  def parse(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end
end
