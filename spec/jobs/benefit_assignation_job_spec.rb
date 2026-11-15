# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitAssignationJob, type: :job do
  fixtures :benefit_configurations, :benefit_rules, :consumers, :companies, :users

  describe "#perform" do
    it "calls apply_to_all_consumers on each benefit configuration" do
      configs = [ benefit_configurations(:monthly), benefit_configurations(:gift) ]
      configs.each do |config|
        expect(config).to receive(:apply_to_all_consumers).and_call_original
      end
      allow(BenefitConfiguration).to receive(:includes).and_return(BenefitConfiguration)
      allow(BenefitConfiguration).to receive(:find_each).and_yield(configs.first).and_yield(configs.last)

      described_class.perform_now
    end

    it "handles and reports errors without crashing the entire job" do
      failing_config = benefit_configurations(:monthly)
      allow(failing_config).to receive(:apply_to_all_consumers).and_raise(StandardError, "Unexpected error")

      allow(BenefitConfiguration).to receive(:includes).and_return(BenefitConfiguration)
      allow(BenefitConfiguration).to receive(:find_each).and_yield(failing_config)

      expect(Rails.error).to receive(:report).with(
        an_instance_of(StandardError),
        context: { benefit_configuration_id: failing_config.id },
        handled: true
      )

      expect { described_class.perform_now }.not_to raise_error
    end

    context "con un subsidio base para toda la empresa" do
      it "asigna el subsidio a un empleado creado después de la configuración" do
        configuration = benefit_configurations(:monthly)
        configuration.update!(applies_to_all: true)

        company = configuration.company

        user = User.create!(
          email: "employee-after-subsidy@example.com",
          name: "Empleado posterior",
          password: "password123456"
        )

        consumer = Consumer.create!(
          user:,
          company:,
          address: "Dirección de prueba",
          birthday: Date.new(2000, 1, 1),
          onboarding_date: Date.current
        )

        expect(consumer.consumer_benefit_configurations).to be_empty
        expect(consumer.benefits).to be_empty

        described_class.perform_now

        expect(
          consumer.benefits.where(benefit_configuration: configuration).sole
        ).to have_attributes(
          percentage: configuration.subsidy_percentage
        )
      end

      it "no asigna el subsidio a un empleado de otra empresa" do
        configuration = benefit_configurations(:monthly)
        configuration.update!(applies_to_all: true)

        other_company = Company.create!(name: "Otra Empresa", address: "Otra 456")
        user = User.create!(
          email: "other-company-employee@example.com",
          name: "Empleado otra empresa",
          password: "password123456"
        )
        other_consumer = Consumer.create!(user:, company: other_company)

        described_class.perform_now

        expect(other_consumer.benefits).to be_empty
      end
    end

    context "con un subsidio especial" do
      include ActiveSupport::Testing::TimeHelpers

      let(:special) do
        BenefitConfiguration.create!(
          company: companies(:gogrow), created_by: users(:admin), name: "Cumpleaños", subsidy_percentage: 20,
          consumers: [ consumers(:one), consumers(:other) ]
        ).tap { it.benefit_rules.create!(type: BirthdayBenefit.name, limit: 1, deadline_days: 3) }
      end

      it "asigna el beneficio solo a quien cumple la condición, dentro de su vigencia" do
        travel_to Date.new(2026, 5, 11) do
          special
          described_class.perform_now
        end

        expect(special.benefits.sole).to have_attributes(consumer: consumers(:one), due_date: Date.new(2026, 5, 13), percentage: 20)
      end

      it "no asigna nada fuera de la vigencia" do
        travel_to Date.new(2026, 5, 14) do
          special
          described_class.perform_now
        end

        expect(special.benefits).to be_empty
      end

      it "no asigna nada si el subsidio está desactivado" do
        travel_to Date.new(2026, 5, 11) do
          special.update!(deactivated_at: Time.current)
          described_class.perform_now
        end

        expect(special.benefits).to be_empty
      end
    end
  end
end
