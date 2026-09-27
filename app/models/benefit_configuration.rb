# frozen_string_literal: true

class BenefitConfiguration < ApplicationRecord
  belongs_to :company
  belongs_to :created_by, class_name: "User"

  has_many :benefits
  has_many :benefit_rules
  has_many :consumer_benefit_configurations
  has_many :consumers, through: :consumer_benefit_configurations

  validates :subsidy_percentage, presence: true,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :ordered, -> { order(effective_from: :desc, created_at: :desc) }

  def self.current_for(company)
    where(company: company).where(effective_from: ..Date.current).ordered.first
  end

  # El beneficio es aplicable a un consumidor si todas sus reglas se cumplen, y si
  # el consumidor está registrado para él.
  def applicable_to?(consumer, date: Date.current)
    consumer.include? consumer &&
      benefit_rules.all? { |rule| rule.applicable_to? consumer, date }
  end

  # Crea los beneficios (Benefit) asociados a esta configuración a todos los consumidores
  # registrados. Esta operación es idempotente: correrla dos veces en el mismo día es
  # equivalente a correrla una.
  def apply_to_all_consumers
    already_granted_ids = Benefit.current.where(benefit_configuration: self).pluck(:consumer_id).to_set
    date = Date.current

    consumers.each do |consumer|
      next if already_granted_ids.include? consumer.id
      next unless benefit_rules.all? { |rule| rule.applicable_to? consumer, date }

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
        next
      end
    end
  end

  private

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
      .map { |rule| rule.benefit_deadline consumer, date }
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
