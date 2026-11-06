# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261106161153_backfill_base_subsidy_consumer_assignments").to_s

# Regresión del defecto del Subsidio Base: los seeds creaban el Benefit mensual
# a mano y no la asociación ConsumerBenefitConfiguration, así que un empleado
# elegible quedaba sin beneficio aunque la configuración de RR. HH. siguiera
# vigente. El backfill completa la asociación y vuelve a generar el Benefit.
RSpec.describe BackfillBaseSubsidyConsumerAssignments, type: :model do
  fixtures :users, :companies, :consumers, :benefit_configurations, :benefit_rules,
           :consumer_benefit_configurations

  let(:company) { companies(:gogrow) }
  let(:admin_user) { users(:admin) }
  let(:consumer) { consumers(:one) }

  def build_base_subsidy
    BenefitConfiguration.new_base_subsidy(
      company:,
      created_by: admin_user,
      subsidy_percentage: 50,
      effective_from: Date.current,
      max_price: 500,
      limit: 20
    )
  end

  def simulate_missing_assignment(configuration)
    configuration.consumer_benefit_configurations.where(consumer:).delete_all
    consumer.benefits.where(benefit_configuration: configuration).delete_all

    expect(
      configuration.consumer_benefit_configurations.find_by(consumer:)
    ).to be_nil
    expect(consumer.benefits.reload).to be_empty
  end

  it "recrea la asociación y el beneficio mensual del empleado elegible" do
    BenefitConfiguration.destroy_all
    Benefit.destroy_all
    ConsumerBenefitConfiguration.destroy_all

    configuration = build_base_subsidy
    configuration.save!
    simulate_missing_assignment(configuration)

    described_class.new.up

    expect(
      configuration.consumer_benefit_configurations.find_by(consumer:)
    ).to be_present

    benefit = consumer.benefits.find_by!(benefit_configuration: configuration)
    expect(benefit).to have_attributes(
      percentage: 50,
      amount: 20,
      max_price: 500,
      status: "current",
      due_date: Date.current.end_of_month
    )

    # Correrlo de nuevo no duplica la asociación ni el beneficio.
    expect { described_class.new.up }.not_to change {
      [
        configuration.consumer_benefit_configurations.where(consumer:).count,
        consumer.benefits.where(benefit_configuration: configuration).count
      ]
    }
  end

  it "no repone el beneficio de una configuración dada de baja" do
    BenefitConfiguration.destroy_all
    Benefit.destroy_all
    ConsumerBenefitConfiguration.destroy_all

    configuration = build_base_subsidy
    configuration.save!
    simulate_missing_assignment(configuration)
    configuration.update!(deactivated_at: Time.current)

    described_class.new.up

    expect(
      configuration.consumer_benefit_configurations.find_by(consumer:)
    ).to be_nil
    expect(consumer.benefits.reload).to be_empty
  end
end
