# frozen_string_literal: true

# Representa una configuración de beneficios para una empresa.
# Las configuraciones pueden tener varias reglas (BenefitRule) o una sola,
# y el beneficio representado por la configuración se aplica solamente si
# se cumplen las condiciones de todas las reglas.
# La configuración solo guarda el nombre y porcentaje de beneficio. Los límites
# de fecha o cantidad dependen de las reglas.
# Con las funciones new_base_subsidy y base_subsidy_for se crean y obtienen
# los subsidios base (o mensuales) de la empresa. Los subsidios mensuales se
# deberían manejar únicamente a través de estas funciones.
# Al crear un BenefitConfiguration, habría que especificar todas sus reglas.
# Los subsidios especiales (cumpleaños, antigüedad, onboarding, premio) son
# configuraciones sin MonthlyBenefit, con una sola regla, que se suman al base.
# Se crean y modifican con save_special_subsidy y se dan de baja con deactivate!,
# que deja vencidos sus beneficios en lugar de borrar el historial.
class BenefitConfiguration < ApplicationRecord
  belongs_to :company
  belongs_to :created_by, class_name: "User"

  has_many :benefits, dependent: :destroy
  has_many :benefit_rules, dependent: :destroy, autosave: true
  has_many :consumer_benefit_configurations, dependent: :destroy
  has_many :consumers, through: :consumer_benefit_configurations
  has_many :benefit_configuration_changes, dependent: :destroy

  validates :subsidy_percentage, presence: true,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  with_options on: :special_subsidy do
    validates :name, presence: true
    validates :subsidy_percentage, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
    validates :consumers, presence: true, unless: :applies_to_all?
    validate :consumers_from_same_company
    validate :single_special_rule
  end

  scope :active, -> { where(deactivated_at: nil) }

  scope :special, -> {
    where.not(id: BenefitRule.where(type: MonthlyBenefit.name).select(:benefit_configuration_id))
  }

  scope :monthly_ordered, -> {
    joins(:benefit_rules)
      .where(benefit_rules: { type: MonthlyBenefit.name })
      .group("benefit_configurations.id")
      .order("MAX(benefit_rules.effective_from) DESC")
  }

  scope :monthly, -> {
    joins(:benefit_rules)
      .where(benefit_rules: { type: MonthlyBenefit.name })
      .distinct
  }

  def self.pending_base_subsidies_for(company, effective_from: Date.current)
    where(company: company)
      .monthly_ordered
      .where(benefit_rules: { effective_from: (effective_from + 1.day).. })
  end

  def self.base_subsidy_for(company, effective_from: Date.current)
    where(company: company)
      .monthly_ordered
      .where(benefit_rules: { effective_from: ..effective_from })
      .first # Obtiene el que tenga effective_from más alto
  end

  def self.new_base_subsidy(company:, created_by:, subsidy_percentage:, effective_from:, max_price:, limit:)
    return BenefitConfiguration.new unless company

    benefit_configuration = company.benefit_configurations.new(
      created_by:,
      name: "Subsidio base",
      subsidy_percentage:
    )
    benefit_configuration.new_monthly_benefit(
      effective_from:,
      max_price:,
      limit:
    )
    company.consumers.each do |consumer|
      benefit_configuration.consumer_benefit_configurations.new consumer:, benefit_configuration:
    end

    benefit_configuration
  end

  def new_monthly_benefit(effective_from:, max_price:, limit:)
    benefit_rules.new(
      type: MonthlyBenefit.name,
      effective_from:,
      max_price:,
      limit:
    )
  end

  # Crea los beneficios (Benefit) asociados a esta configuración a todos los consumidores
  # registrados. Esta operación es idempotente: correrla dos veces en el mismo día es
  # equivalente a correrla una.
  def apply_to_all_consumers
    return if deactivated_at?

    already_granted_ids = Benefit.current.where(benefit_configuration: self).pluck(:consumer_id).to_set
    future_granted_ids = Benefit.future.where(benefit_configuration: self).pluck(:consumer_id).to_set
    date = Date.current

    target_consumers.each do |consumer|
      apply_current(consumer, date) unless already_granted_ids.include? consumer.id
      apply_future(consumer, date) unless future_granted_ids.include? consumer.id
    end
  end

  def apply_current(consumer, date)
    return unless benefit_rules.all? { |rule| rule.applicable_to? consumer, date: }

    begin
      consumer.benefits.create!(
        amount: benefit_limit,
        due_date: benefit_deadline(consumer, date),
        percentage: subsidy_percentage,
        description: name,
        status: :current,
        benefit_configuration: self
      )
    rescue ActiveRecord::RecordNotUnique
      # Si llegamos a este caso hay un error de concurrencia: se está corriendo esta
      # misma función dos veces a la vez. No tenemos nada para hacer y podemos ignorar
      # el error.
      nil
    end
  end

  def apply_future(consumer, date)
    return unless benefit_rules.any? { |rule| rule.future_applicable_to? consumer, date: }

    begin
      consumer.benefits.create!(
        amount: benefit_limit,
        due_date: future_benefit_deadline(consumer, date),
        percentage: subsidy_percentage,
        description: name,
        status: :future,
        benefit_configuration: self
      )
    rescue ActiveRecord::RecordNotUnique
      # Si llegamos a este caso hay un error de concurrencia: se está corriendo esta
      # misma función dos veces a la vez. No tenemos nada para hacer y podemos ignorar
      # el error.
      nil
    end
  end

  # Con applies_to_all la configuración alcanza a toda la empresa, incluidos los
  # empleados que entren después de crearla.
  def target_consumers
    applies_to_all? ? Consumer.where(company_id:) : consumers
  end

  # Pone al día los beneficios vigentes después de un cambio: actualiza los de quienes
  # siguen cumpliendo la condición (sin duplicarlos, así se conserva lo ya usado),
  # vence los de quienes dejaron de cumplirla y asigna los que falten.
  def refresh_benefits
    date = Date.current

    benefits.current.includes(:consumer).find_each do |benefit|
      consumer = benefit.consumer

      if target_consumers.include?(consumer) && benefit_rules.all? { |rule| rule.applicable_to? consumer, date: }
        benefit.update!(
          amount: benefit_limit,
          due_date: benefit_deadline(consumer, date),
          percentage: subsidy_percentage,
          description: name
        )
      else
        benefit.expired!
      end
    end

    apply_to_all_consumers
  end

  def save_special_subsidy(by:, name:, subsidy_percentage:, applies_to_all:, consumer_ids:, condition:)
    action = new_record? ? :created : :updated

    transaction do
      assign_attributes(name:, subsidy_percentage:, applies_to_all:)
      self.consumers = applies_to_all? ? [] : Consumer.where(id: consumer_ids)
      assign_special_rule(condition)
      raise ActiveRecord::Rollback unless save(context: :special_subsidy)

      benefit_rules.reload
      record_change! action, by
      refresh_benefits
      true
    end || false
  end

  def deactivate!(by:)
    transaction do
      update!(deactivated_at: Time.current)
      benefits.current.update_all(status: :expired, updated_at: Time.current)
      record_change! :deactivated, by
    end
  end

  # La condición del subsidio especial en los términos del formulario de RRHH: la
  # validez se guarda en días (o como fecha límite en el premio) y se devuelve en la
  # unidad más grande que la represente exacta.
  def special_condition
    case rule = benefit_rules.to_a.first
    when SeniorityBenefit
      { type: "seniority", min_years: rule.min_years }
    when BirthdayBenefit, OnboardingBenefit
      { type: rule.is_a?(BirthdayBenefit) ? "birthday" : "onboarding", limit: rule.limit, **validity_in_days(rule.deadline_days) }
    when GiftBenefit
      { type: "gift", limit: rule.limit, effective_from: rule.effective_from, **validity_between(rule.effective_from, rule.deadline_date) }
    end
  end

  private

  def assign_special_rule(condition)
    attributes = special_rule_attributes(condition)
    rule = benefit_rules.to_a.first

    if attributes && rule&.type == attributes[:type]
      rule.assign_attributes(attributes)
    else
      benefit_rules.each(&:mark_for_destruction)
      benefit_rules.build(attributes) if attributes
    end
  end

  # Una semana son 7 días y un mes, 30: la validez de cumpleaños y onboarding se
  # guarda como deadline_days. La del premio se suma a la fecha de inicio en el
  # calendario, porque tiene una fecha límite real.
  def special_rule_attributes(condition)
    amount = condition[:validity_amount].presence&.to_i
    unit = condition[:validity_unit].presence_in(%w[days weeks months])

    case condition[:type]
    when "seniority"
      { type: SeniorityBenefit.name, min_years: condition[:min_years] }
    when "birthday", "onboarding"
      {
        type: (condition[:type] == "birthday" ? BirthdayBenefit : OnboardingBenefit).name,
        limit: condition[:limit],
        deadline_days: (amount * { "days" => 1, "weeks" => 7, "months" => 30 }[unit] if amount && unit)
      }
    when "gift"
      effective_from = parse_date(condition[:effective_from])
      {
        type: GiftBenefit.name,
        limit: condition[:limit],
        effective_from:,
        deadline_date: (effective_from.advance(unit.to_sym => amount) if effective_from && amount && unit)
      }
    end
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end

  def validity_in_days(days)
    if days.to_i.positive? && (days % 30).zero?
      { validity_amount: days / 30, validity_unit: "months" }
    elsif days.to_i.positive? && (days % 7).zero?
      { validity_amount: days / 7, validity_unit: "weeks" }
    else
      { validity_amount: days, validity_unit: "days" }
    end
  end

  def validity_between(from, to)
    return { validity_amount: nil, validity_unit: "days" } unless from && to

    months = (to.year * 12 + to.month) - (from.year * 12 + from.month)
    return { validity_amount: months, validity_unit: "months" } if months.positive? && from.advance(months:) == to

    days = (to - from).to_i
    (days % 7).zero? ? { validity_amount: days / 7, validity_unit: "weeks" } : { validity_amount: days, validity_unit: "days" }
  end

  def record_change!(action, user)
    benefit_configuration_changes.create!(
      action:,
      user:,
      details: { name:, subsidy_percentage:, applies_to_all:, consumer_ids: consumers.map(&:id), condition: special_condition }
    )
  end

  def consumers_from_same_company
    errors.add(:consumers, :invalid) if consumers.any? { |consumer| consumer.company_id != company_id }
  end

  def single_special_rule
    rules = benefit_rules.reject(&:marked_for_destruction?)
    errors.add(:condition_type, :blank) unless rules.one? && !rules.first.is_a?(MonthlyBenefit)
  end

  # Devuelve el menor límite impuesto por las reglas. Si no hay límite, devuelve nil
  def benefit_limit
    benefit_rules
      .map(&:benefit_limit)
      .filter { |limit| !limit.nil? }
      .min
  end

  # Devuelve el menor deadline impuesto por las reglas. Si no hay deadlines, devuelve nil
  def benefit_deadline(consumer, date)
    benefit_rules
      .map { |rule| rule.benefit_deadline consumer, date: }
      .filter { |deadline| !deadline.nil? }
      .min
  end
end

# == Schema Information
#
# Table name: benefit_configurations
#
#  id                 :bigint           not null, primary key
#  applies_to_all     :boolean          default(FALSE)
#  deactivated_at     :datetime
#  name               :string
#  subsidy_percentage :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  company_id         :bigint           not null
#  created_by_id      :bigint           not null
#
# Indexes
#
#  index_benefit_configurations_on_company_id     (company_id)
#  index_benefit_configurations_on_created_by_id  (created_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#
