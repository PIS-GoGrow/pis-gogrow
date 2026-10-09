# frozen_string_literal: true

# Crea un plato guardado y lo programa según la agenda del formulario, con los
# mismos modos que Menus::Update. Un plato nuevo no tiene programaciones ni
# variantes que cuidar, así que la agenda (o el día, en "single") queda directo
# en el plato guardado, también en "range".
class Menus::Create
  attr_reader :menu, :errors

  def initialize(provider:, attributes:, agenda:)
    @menu = provider.menus.new(attributes)
    @agenda = agenda.to_h.symbolize_keys
    @errors = @menu.errors
  end

  def call
    @menu.validate
    validate_agenda
    return false if @errors.any?

    Menu.transaction do
      @menu.save!
      program
      Menus::AgendaScheduler.call(@menu)
    end

    true
  end

  private

  def mode = Menus::Update::MODES.include?(@agenda[:mode]) ? @agenda[:mode] : "none"
  def date = parse(:date)
  def starts_on = parse(:starts_on)
  def ends_on = parse(:ends_on)
  def weekdays = Array(@agenda[:weekdays]).map(&:to_i).uniq.sort

  def parse(key)
    Date.iso8601(@agenda[key].to_s)
  rescue Date::Error
    nil
  end

  def program
    case mode
    when "single" then @menu.schedules.create!(date:, amount: @agenda[:amount])
    when "weekly" then @menu.agendas.create!(weekdays:, starts_on:, amount: @agenda[:amount])
    when "range" then @menu.agendas.create!(weekdays:, starts_on:, ends_on:, amount: @agenda[:amount])
    end
  end

  def validate_agenda
    case mode
    when "single"
      add_agenda_error(:invalid_date) unless date && date >= Date.current && date.on_weekday? && date <= Calendar.new.maximum_publish_date
    when "weekly", "range"
      add_agenda_error(:invalid_date) unless starts_on && starts_on >= Date.current
      add_agenda_error(:invalid_range) if mode == "range" && !(ends_on && starts_on && ends_on >= starts_on)
      add_agenda_error(:invalid_weekdays) unless weekdays.any? && weekdays.all? { (1..5).cover?(it) }
    end

    return if mode == "none"

    add_agenda_error(:invalid_amount) unless MenuAgenda.new(amount: @agenda[:amount]).tap(&:validate).errors[:amount].empty?
  end

  def add_agenda_error(type)
    @errors.add(:agenda, I18n.t("validations.menu_agenda.#{type}"))
  end
end
